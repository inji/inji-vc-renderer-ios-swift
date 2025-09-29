import Foundation

class PlaceholderReplacementHelper {
    private let traceabilityId: String
    private let qrCodeGenerator: QrCodeGeneratorProtocol = QrCodeGenerator() as QrCodeGeneratorProtocol

    
    init(traceabilityId: String) {
        self.traceabilityId = traceabilityId
    }
    
    func replaceSvgPlaceholders(
        svgTemplate: String,
        vcJson: [String: Any],
        renderMethodElement: [String: Any],
        vcJsonString: String
    ) throws -> String {
        let svgWithQrCodeReplaced = replaceQrCodePlaceholder(svgTemplate: svgTemplate, vcJsonString: vcJsonString)
        return try replaceVcPlaceholders(svgTemplate: svgWithQrCodeReplaced, vcJson: vcJson, element: renderMethodElement)
    }
    
    private func replaceVcPlaceholders(svgTemplate: String, vcJson: [String: Any], element: [String: Any])throws -> String {
        var renderProperties: [String]? = nil
                if let template = element[Constants.TEMPLATE] as? [String: Any],
                   let renderProperty = template[Constants.RENDER_PROPERTY] as? [String] {
                    renderProperties = renderProperty
                }
        return  try JsonPointerResolver.replacePlaceholders(
             svgTemplate: svgTemplate,
             inputJson: vcJson,
            renderProperties: renderProperties,
            traceabilityId: traceabilityId
        )

    }
    
    private func replaceQrCodePlaceholder(
        svgTemplate: String,
            vcJsonString: String
        ) -> String {
            guard svgTemplate.contains(Constants.QR_CODE_PLACEHOLDER) else {
                return svgTemplate
            }

            let qrBase64: String?
            do {
                qrBase64 = try qrCodeGenerator.generateQRCodeImage(
                    vcJson: vcJsonString,
                    traceabilityId: traceabilityId
                )
            } catch {
                qrBase64 = nil
            }

            let (finalQrBase64, imageId): (String, String) = {
                if let qr = qrBase64, !qr.isEmpty {
                    return (qr, Constants.QR_CODE_IMAGE_ID)
                } else {
                    return (Constants.FALLBACK_QR_CODE, Constants.QR_CODE_FALLBACK_IMAGE_ID)
                }
            }()

            let qrImageTag = "\(Constants.QR_IMAGE_PREFIX),\(finalQrBase64)"

            return svgTemplate
                .replacingOccurrences(of: Constants.QR_CODE_PLACEHOLDER, with: qrImageTag)
                .replacingOccurrences(of: Constants.QR_CODE_IMAGE_ID, with: imageId)
        }
}
