import Foundation
import CryptoKit

class TemplateHelper {
    private let traceabilityId: String
    static var networkHandler: NetworkManagerProtocol = NetworkManager()

    public let className = String(describing: TemplateHelper.self)
    
    init(traceabilityId: String) {
        self.traceabilityId = traceabilityId
    }
    

    /// Extracts an SVG template after validation
    func extractSVG(renderMethod: [String: Any],
                                   vcJsonString: String) throws -> [String] {

        try validateSvgMustacheRenderSuite(renderMethod)
        try validateTemplateRenderMethodType(renderMethod)

        guard let templateValue = renderMethod[Constants.template] as? [String: Any] else {
            throw InvalidRenderMethodException(traceabilityId: traceabilityId, className: className)
        }

        guard let templateId = templateValue[Constants.id] as? String else {
            throw MissingTemplateIdException(traceabilityId: traceabilityId, className: className)
        }

        var templateResponse: TemplateResponse
           do {
               templateResponse = try TemplateHelper.networkHandler.fetch(url: templateId, traceabilityId: traceabilityId)
           } catch {
               throw SvgFetchException(traceabilityId: traceabilityId, className: className, exceptionMessage: error.localizedDescription)
           }
        
        guard !templateResponse.body.isEmpty else {
            throw SvgFetchException(
                traceabilityId: traceabilityId,
                className: String(describing: NetworkManager.self),
                exceptionMessage: "Empty response body"
            )
        }
        
        let digestMultibase = templateValue[Constants.digestMultibase] as? String
        if let digestMultibase = digestMultibase,
           try !validateDigestMultibase(svgString: templateResponse.body, digestMultibase: digestMultibase) {
            throw MultibaseValidationException(
                traceabilityId: traceabilityId,
                className: String(describing: Self.self),
                exceptionMessage: "Mismatch between fetched SVG and provided digestMultibase"
            )
        }
        return try extractSVGList(templateResponse: templateResponse)
    }
    
    /*** If contentType is application/xml, extract SVGs from the pageSet, else return the body as a single-item list ***/
    private func extractSVGList(templateResponse: TemplateResponse) throws -> [String] {
        if templateResponse.isXmlTemplate() {
            return try XMLHelper(traceabilityId: traceabilityId)
                .getSVGListFromPageSet(xml: templateResponse.body)
        } else {
            return [templateResponse.body]
        }
    }
    
    func validateDigestMultibase(svgString: String, digestMultibase: String) throws -> Bool {
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
    
    private func base64UrlNoPadDecode(_ string: String) -> Data? {
        var base64 = string
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        
        let padding = 4 - (base64.count % 4)
        if padding < 4 {
            base64.append(String(repeating: "=", count: padding))
        }
        
        return Data(base64Encoded: base64)
    }
    
    func parseRenderMethod(_ jsonObject: [String: Any]) throws -> [[String: Any]] {
        guard let renderMethodValue = jsonObject[Constants.renderMethod] else {
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
    
    private func isSvgMustacheRenderSuite(_ renderMethod: [String: Any]) -> Bool {
        let renderSuite = renderMethod[Constants.renderSuite] as? String ?? ""
        return renderSuite == Constants.svgMustache
    }
    
    private func isTemplateRenderMethodType(_ renderMethod: [String: Any]) -> Bool {
        let type = renderMethod[Constants.type] as? String ?? ""
        return type == Constants.templateRenderMethod
    }
    
    
    func validateSvgMustacheRenderSuite(_ renderMethod: [String: Any]) throws {
        if !isSvgMustacheRenderSuite(renderMethod) {
            throw InvalidRenderSuiteException(traceabilityId: traceabilityId, className: className)
        }
    }
    
    func validateTemplateRenderMethodType(_ renderMethod: [String: Any]) throws {
        if !isTemplateRenderMethodType(renderMethod) {
            throw InvalidRenderMethodTypeException(traceabilityId: traceabilityId, className: className)
        }
    }
    
    func parseVcJson(vcJsonString: String) throws -> [String: Any] {
       do {
           guard let data = vcJsonString.data(using: .utf8) else {
               throw VcRendererException(
                errorCode: VcRendererErrorCodes.invalidVcJson,
                   message: "Invalid JSON input (data encoding failed)",
                   className: String(describing: InjiVcRenderer.self),
                   traceabilityId: traceabilityId
               )
           }
           
           guard let parsed = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
               throw VcRendererException(
                   errorCode: VcRendererErrorCodes.invalidVcJson,
                   message: "Invalid JSON input (not a dictionary)",
                   className: String(describing: InjiVcRenderer.self),
                   traceabilityId: traceabilityId
               )
           }
           
           return parsed
       } catch {
           throw VcRendererException(
            errorCode: VcRendererErrorCodes.invalidVcJson,
               message: "Invalid JSON input (\(error.localizedDescription))",
               className: String(describing: InjiVcRenderer.self),
               traceabilityId: traceabilityId
           )
       }
   }
    
}
