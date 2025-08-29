import Foundation

public class SvgPlaceholderHelper {
    
    private static let PLACEHOLDER_REGEX_PATTERN = #"\{\{(/[^}]+)\}\}"#
    
    public static func replacePlaceholders(svgTemplate: String, jsonObject: [String: Any]) -> String {
        let regex = try! NSRegularExpression(pattern: PLACEHOLDER_REGEX_PATTERN)
        let svgWidth = SvgHelper.extractSvgWidth(svgTemplate: svgTemplate) ?? 100
        let locale = SvgHelper.extractSvgLocale(svgTemplate: svgTemplate)
        
        let nsRange = NSRange(svgTemplate.startIndex..., in: svgTemplate)
        
        var result = svgTemplate
        let matches = regex.matches(in: svgTemplate, range: nsRange)
        
        for match in matches.reversed() { // reverse to avoid messing ranges while replacing
            if let range = Range(match.range(at: 1), in: svgTemplate) {
                let path = String(svgTemplate[range])
                let value = getValueFromJsonPath(jsonObject: jsonObject, path: path, svgWidth: svgWidth, locale: locale) ?? "-"
                if let rangeInResult = Range(match.range, in: result) {
                    result.replaceSubrange(rangeInResult, with: "\(value)")
                }
            }
        }

        
        return result
    }
    
    static func preserveRenderProperty(svgTemplate: String, renderProperties: [String]) -> String {
        let regex = try! NSRegularExpression(pattern: #"\{\{[^}]+}}"#)
        let nsRange = NSRange(svgTemplate.startIndex..., in: svgTemplate)
        
        var result = svgTemplate
        let matches = regex.matches(in: svgTemplate, range: nsRange)
        
        for match in matches.reversed() {
            if let range = Range(match.range, in: result) {
                let placeholder = String(result[range])
                let path = placeholder
                    .replacingOccurrences(of: "{{", with: "")
                    .replacingOccurrences(of: "}}", with: "")
                    .trimmingCharacters(in: .whitespaces)
                
                if !renderProperties.contains(path) {
                    result.replaceSubrange(range, with: "-")
                }
            }
        }
        
        return result
    }
    
    private static func getConcatenatedAddress(credentialSubject: [String: Any], lang: String = Constants.DEFAULT_LOCALE) -> String {
        let fields = [
            Constants.ADDRESS_LINE_1,
            Constants.ADDRESS_LINE_2,
            Constants.ADDRESS_LINE_3,
            Constants.CITY,
            Constants.PROVINCE,
            Constants.REGION,
            Constants.POSTAL_CODE
        ]
        
        var parts: [String] = []
        
        for field in fields {
            guard let fieldValue = credentialSubject[field] else { continue }
            
            let value: String? = {
                if let arr = fieldValue as? [[String: Any]] {
                    return extractFromLangArray(array: arr, lang: lang)
                } else if let str = fieldValue as? String {
                    return str
                }
                return nil
            }()
            
            if let v = value, !v.isEmpty {
                parts.append(v)
            }
        }
        
        return parts.joined(separator: ", ")
    }
    
    private static func extractFromLangArray(array: [[String: Any]], lang: String) -> String? {
        // First try locale
        if let match = array.first(where: { ($0["language"] as? String) == lang }) {
            return match["value"] as? String
        }
        // Fallback to English
        if let match = array.first(where: { ($0["language"] as? String) == "eng" }) {
            return match["value"] as? String
        }
        // Fallback to first
        return array.first?["value"] as? String
    }
    
    static func getValueFromJsonPath(
        jsonObject: [String: Any],
        path: String,
        svgWidth: Int,
        isDefaultHandled: Bool = false,
        locale: String = Constants.DEFAULT_LOCALE
    ) -> Any? {
        let keys = path.trimmingCharacters(in: CharacterSet(charactersIn: "/")).split(separator: "/").map { String($0) }
        
        if keys.last == Constants.CONCATENATED_ADDRESS {
            if let subject = jsonObject[Constants.CREDENTIAL_SUBJECT] as? [String: Any] {
                let address = getConcatenatedAddress(credentialSubject: subject, lang: locale)
                return SvgMultilineFormatter.chunkAddressFields(address, svgWidth: svgWidth)
            }
            return nil
        }
        
        var current: Any? = jsonObject
        
        for (i, k) in keys.enumerated() {
            if let dict = current as? [String: Any] {
                current = dict[k]
            } else if let array = current as? [Any] {
                if let index = Int(k), index < array.count {
                    current = array[index]
                } else if i == keys.count - 1, let langArray = array as? [[String: Any]] {
                    current = extractFromLangArray(array: langArray, lang: k)
                } else {
                    current = nil
                }
            } else {
                current = nil
            }
            
            if current == nil && !isDefaultHandled {
                let parentPath = keys.dropLast().joined(separator: "/")
                return getValueFromJsonPath(
                    jsonObject: jsonObject,
                    path: "\(parentPath)/\(Constants.DEFAULT_LOCALE)",
                    svgWidth: svgWidth,
                    isDefaultHandled: true,
                    locale: locale
                )
            }
        }
        
        if let dict = current as? [String: Any] {
            let lastKey = keys.last ?? ""
            return dict[lastKey] ?? dict[Constants.DEFAULT_LOCALE]
        }
        
        if let array = current as? [Any] {
            if isLanguageArray(array: array) {
                return extractFromLangArray(array: array as! [[String: Any]], lang: locale)
            } else {
                return SvgMultilineFormatter.chunkArrayFields(array, svgWidth: svgWidth)
            }
        }
        
        return current
    }
    
    private static func isLanguageArray(array: [Any]) -> Bool {
        guard let first = array.first as? [String: Any] else { return false }
        return first["language"] != nil && first["value"] != nil
    }
}
