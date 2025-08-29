import Foundation
import pixelpass
import Foundation

class InjiVcRenderer {
    
 
    
    /// Renders SVG templates defined in the VC's renderMethod section.
    /// Supports fetching templates from URLs and data URIs.
    /// Replaces placeholders in the templates with values from the VC JSON.
    ///
    /// - Parameter vcJsonString: The Verifiable Credential as a JSON string.
    /// - Returns: A list of rendered SVG strings. Empty list if no valid render methods found or on error.
    func renderSvg(vcJsonString: String) -> [String] {
        do {
            // Parse JSON string into dictionary
            guard let data = vcJsonString.data(using: .utf8),
                  let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                return []
            }
            
            // Check if renderMethod exists
            guard let renderMethodValue = jsonObject[Constants.RENDER_METHOD] else {
                return []
            }
            
            // Normalize renderMethod to an array
            var renderMethodArray: [[String: Any]] = []
            if let array = renderMethodValue as? [[String: Any]] {
                renderMethodArray = array
            } else if let dict = renderMethodValue as? [String: Any], !dict.isEmpty {
                renderMethodArray = [dict]
            }
            
            var results: [String] = []
            
            for renderMethod in renderMethodArray {
                if let svgTemplate = SvgHelper.extractSvgTemplate(renderMethod: renderMethod, vcJsonString: vcJsonString) {
                    let renderedSvg = SvgPlaceholderHelper.replacePlaceholders(svgTemplate: svgTemplate, jsonObject: jsonObject)
                    results.append(renderedSvg)
                }
            }
            
            return results
            
        } catch {
            print("Error parsing or rendering SVG: \(error)")
            return []
        }
    }
}


