import Foundation

class SvgHelper {
    // 👇 dependency injection point
    static var networkHandler: NetworkHandlerProtocol = NetworkHandler() as NetworkHandlerProtocol
    static var qrCodeGenerator: QrCodeGeneratorProtocol = QrCodeGenerator() as QrCodeGeneratorProtocol

    static func extractSvgTemplate(renderMethod: [String: Any], vcJsonString: String) -> String {
        guard isSvgMustacheTemplate(renderMethod: renderMethod) else { return "" }

        guard let templateValue = renderMethod[Constants.TEMPLATE] as? [String: Any],
              let templateId = templateValue[Constants.ID] as? String else {
            return ""
        }

        // Use the injected handler
        guard var rawSvg = networkHandler.fetchSvgAsText(url: templateId) else {
            return ""
        }

        rawSvg = injectQrCodeIfNeeded(svg: rawSvg, vcJsonString: vcJsonString)
        return rawSvg
    }

    private static func injectQrCodeIfNeeded(svg: String, vcJsonString: String) -> String {
        guard svg.contains(Constants.QR_CODE_PLACEHOLDER) else { return svg }
        let qrBase64 = qrCodeGenerator.generateQRCodeImage(vcJson: vcJsonString)
        let qrImageTag = "\(Constants.QR_IMAGE_PREFIX),\(qrBase64)"
        return svg.replacingOccurrences(of: Constants.QR_CODE_PLACEHOLDER, with: qrImageTag)
    }

    static func isSvgMustacheTemplate(renderMethod: [String: Any]) -> Bool {
        let type = renderMethod[Constants.TYPE] as? String ?? ""
        let renderSuite = renderMethod[Constants.RENDER_SUITE] as? String ?? ""
        return type == Constants.TEMPLATE_RENDER_METHOD && renderSuite == Constants.SVG_MUSTACHE
    }

    static func parseRenderMethod(_ jsonObject: [String: Any]) -> [Any] {
        guard let renderMethodValue = jsonObject[Constants.RENDER_METHOD] else {
            return []
        }

        if let array = renderMethodValue as? [Any] {
            return array
        } else if let dict = renderMethodValue as? [String: Any] {
            return [dict]
        } else {
            return []
        }
    }
}

protocol NetworkHandlerProtocol {
    func fetchSvgAsText(url: String) -> String?
}

protocol QrCodeGeneratorProtocol {
    func generateQRCodeImage(vcJson: String) -> String
}
