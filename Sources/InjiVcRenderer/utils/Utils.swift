import Foundation
import CryptoKit

class Utils {
    static var networkHandler: NetworkManagerProtocol = NetworkManager() as NetworkManagerProtocol
    static var qrCodeGenerator: QrCodeGeneratorProtocol = QrCodeGenerator() as QrCodeGeneratorProtocol

    public static let className = String(describing: Utils.self)
    
    

    /// Extracts an SVG template after validation and QR injection
    static func extractSvgTemplate(renderMethod: [String: Any],
                                   vcJsonString: String,
                                   traceabilityId: String) throws -> String {

        try ensureSvgMustacheRenderSuite(renderMethod: renderMethod, traceabilityId: traceabilityId)
        try ensureTemplateRenderMethodType(renderMethod: renderMethod, traceabilityId: traceabilityId)

        guard let templateValue = renderMethod[Constants.TEMPLATE] as? [String: Any] else {
            throw InvalidRenderMethodTypeException(traceabilityId: traceabilityId, className: className)
        }

        guard let templateId = templateValue[Constants.ID] as? String else {
            throw MissingTemplateIdException(traceabilityId: traceabilityId, className: className)
        }

        var rawSvg: String
           do {
               rawSvg = try networkHandler.fetchSvgAsText(url: templateId, traceabilityId: traceabilityId)
           } catch {
               throw SvgFetchException(traceabilityId: traceabilityId, className: className, exceptionMessage: error.localizedDescription)
           }
        let digestMultibase = templateValue[Constants.DIGEST_MULTIBASE] as? String
        if let digestMultibase = digestMultibase,
           try !validateDigestMultibase(traceabilityId: traceabilityId, svgString: rawSvg, digestMultibase: digestMultibase) {
            throw MultibaseValidationException(
                traceabilityId: traceabilityId,
                className: String(describing: Self.self),
                exceptionMessage: "Mismatch between fetched SVG and provided digestMultibase"
            )
        }

        rawSvg = try injectQrCodeIfNeeded(svg: rawSvg, vcJsonString: vcJsonString, traceabilityId: traceabilityId)
        return rawSvg
    }
    
    private static func injectQrCodeIfNeeded(
        svg: String,
        vcJsonString: String,
        traceabilityId: String
    ) throws -> String {
        guard svg.contains(Constants.QR_CODE_PLACEHOLDER) else {
            return svg
        }

        do {
            let qrBase64 = try qrCodeGenerator.generateQRCodeImage(vcJson: vcJsonString, traceabilityId: traceabilityId)
            let qrImageTag = "\(Constants.QR_IMAGE_PREFIX),\(qrBase64)"
            return svg.replacingOccurrences(of: Constants.QR_CODE_PLACEHOLDER, with: qrImageTag)
        } catch {
            let fallbackBase64 = Constants.FALLBACK_QR_CODE
            let qrImageTag = "\(Constants.QR_IMAGE_PREFIX),\(fallbackBase64)"
            return svg.replacingOccurrences(of: Constants.QR_CODE_PLACEHOLDER, with: qrImageTag)
        }
    }


    /// Ensures render suite is SVG Mustache
    static func ensureSvgMustacheRenderSuite(renderMethod: [String: Any],
                                             traceabilityId: String) throws {
        let renderSuite = renderMethod[Constants.RENDER_SUITE] as? String ?? ""
        if renderSuite != Constants.SVG_MUSTACHE {
            throw InvalidRenderSuiteException(traceabilityId: traceabilityId, className: className)
        }
    }

    /// Ensures render method type is Template
    static func ensureTemplateRenderMethodType(renderMethod: [String: Any],
                                               traceabilityId: String) throws {
        let type = renderMethod[Constants.TYPE] as? String ?? ""
        if type != Constants.TEMPLATE_RENDER_METHOD {
            throw InvalidRenderMethodTypeException(traceabilityId: traceabilityId, className: className)
        }
    }

    static func parseRenderMethod(_ jsonObject: [String: Any],
                                  traceabilityId: String) throws -> [[String: Any]] {
        guard let renderMethodValue = jsonObject[Constants.RENDER_METHOD] else {
            throw InvalidRenderMethodException(traceabilityId: traceabilityId, className: className)
        }

        if let array = renderMethodValue as? [[String: Any]] {
            if array.isEmpty || array.contains(where: { $0.isEmpty }) {
                throw InvalidRenderMethodException(traceabilityId: traceabilityId, className: className)
            }
            return array
        } else if let dict = renderMethodValue as? [String: Any] {
            if dict.isEmpty {
                throw InvalidRenderMethodException(traceabilityId: traceabilityId, className: className)
            }
            return [dict]
        } else {
            throw InvalidRenderMethodException(traceabilityId: traceabilityId, className: className)
        }
    }
    
    static func validateDigestMultibase(traceabilityId: String, svgString: String, digestMultibase: String) throws -> Bool {
        guard digestMultibase.hasPrefix("u") else {
            throw MultibaseValidationException(traceabilityId: traceabilityId, className: className,  exceptionMessage: "digestMultibase must start with 'u'")
        }
        
        let encodedPart = String(digestMultibase.dropFirst())
        guard let decoded = base64UrlNoPadDecode(encodedPart) else {
            throw MultibaseValidationException(traceabilityId: traceabilityId, className: className,  exceptionMessage: "Base64 Decoding error")
        }
        
        guard decoded.count == 34 else {
            throw MultibaseValidationException(traceabilityId: traceabilityId, className: className,  exceptionMessage: "Invalid multihash length")
        }
        
        guard decoded[0] == 0x12 && decoded[1] == 0x20 else {
            throw MultibaseValidationException(traceabilityId: traceabilityId, className: className,  exceptionMessage: "Unsupported multihash prefix")
        }
        
        let expectedHash = decoded.subdata(in: 2..<34)
        let actualHash = Data(SHA256.hash(data: Data(svgString.utf8)))
        
        return expectedHash == actualHash
    }
    
    private static func base64UrlNoPadDecode(_ string: String) -> Data? {
        var base64 = string
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        
        let padding = 4 - (base64.count % 4)
        if padding < 4 {
            base64.append(String(repeating: "=", count: padding))
        }
        
        return Data(base64Encoded: base64)
    }
}


