import Foundation

enum SvgHelper {
    
    static func extractSvgTemplate(renderMethod: [String: Any], vcJsonString: String, networkHandler: NetworkHandler = NetworkHandler()) -> String? {
        guard isSvgMustacheTemplate(renderMethod: renderMethod) else { return nil }
        
        if let templateValue = renderMethod[Constants.TEMPLATE] {
            var svgTemplate: String? = nil
            
            switch templateValue {
            case let templateObj as [String: Any]:
                if let id = templateObj[Constants.ID] as? String {
                    var rawSvg = networkHandler.fetchSvgAsText(url: id) ?? ""
                    
                    if ((rawSvg.contains(Constants.QR_CODE_PLACEHOLDER))) {
                           rawSvg = injectQrCodePlaceholder(svgTemplate: rawSvg , vcJsonString: vcJsonString)
                       }
                    
                    if let renderPropsArray = templateObj[Constants.RENDER_PROPERTY] as? [String] {
                        rawSvg = SvgPlaceholderHelper.preserveRenderProperty(svgTemplate: rawSvg, renderProperties: renderPropsArray)
                    }
                    
                    svgTemplate = rawSvg
                }
                
            case let templateStr as String:
                var rawSvg = decodeSvgDataUriToSvgTemplate(templateStr)
                
                if ((rawSvg?.contains(Constants.QR_CODE_PLACEHOLDER)) != nil) {
                       rawSvg = injectQrCodePlaceholder(svgTemplate: rawSvg ?? "", vcJsonString: vcJsonString)
                   }
                
                svgTemplate = rawSvg
                
            default:
                break
            }
            
            return svgTemplate
        }
        
        return nil
    }
    
    
    static func extractSvgLocale(svgTemplate: String) -> String {
        let pattern = #"<svg[^>]*\blang\s*=\s*["']([a-zA-Z-]+)["']"#
        if let regex = try? NSRegularExpression(pattern: pattern),
           let match = regex.firstMatch(in: svgTemplate, range: NSRange(svgTemplate.startIndex..., in: svgTemplate)),
           let range = Range(match.range(at: 1), in: svgTemplate) {
            return String(svgTemplate[range])
        }
        return Constants.DEFAULT_LOCALE
    }
    
    static func extractSvgWidth(svgTemplate: String) -> Int? {
        let pattern = #"<svg[^>]*\bwidth\s*=\s*["'](\d+)(px)?["']"#
        if let regex = try? NSRegularExpression(pattern: pattern),
           let match = regex.firstMatch(in: svgTemplate, range: NSRange(svgTemplate.startIndex..., in: svgTemplate)),
           let range = Range(match.range(at: 1), in: svgTemplate) {
            return Int(svgTemplate[range])
        }
        return nil
    }
    
    static func isSvgMustacheTemplate(renderMethod: [String: Any]) -> Bool {
        let type = renderMethod[Constants.TYPE] as? String ?? ""
        let renderSuite = renderMethod[Constants.RENDER_SUITE] as? String ?? ""
        return type == Constants.TEMPLATE_RENDER_METHOD && renderSuite == Constants.SVG_MUSTACHE
    }
    
    static func jsonArrayToList(jsonArray: [Any]) -> [String] {
        return jsonArray.compactMap { $0 as? String }
    }
    
    private static func decodeSvgDataUriToSvgTemplate(_ svgDataUri: String) -> String? {
        guard let range = svgDataUri.range(of: "base64,") else {
            return nil
        }
        
        let base64Part = String(svgDataUri[range.upperBound...])
        
        guard let decodedData = Data(base64Encoded: base64Part) else {
            return nil
        }
        
        return String(data: decodedData, encoding: .utf8)
    }
    
    private static func injectQrCodePlaceholder(svgTemplate: String, vcJsonString: String) -> String {
        let qrBase64 = QrCodeGenerator().generateQRCodeImage(vcJson: vcJsonString)
        let qrImageTag = "\(Constants.QR_IMAGE_PREFIX),\(qrBase64)"
        return svgTemplate.replacingOccurrences(of: Constants.QR_CODE_PLACEHOLDER, with: qrImageTag)
    }
    
}
