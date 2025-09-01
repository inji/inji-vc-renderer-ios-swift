import Foundation

class InjiVcRenderer {
    /**
     Renders SVG templates defined in the VC's renderMethod section.
     Supports fetching templates from URLs and data URIs.
     Replaces placeholders in the templates with values from the VC JSON.

     - Parameter vcJsonString: The Verifiable Credential as a JSON string.
     - Returns: A list of rendered SVG strings. Empty list if no valid render methods found or on error.
     */
    func renderSvg(vcJsonString: String) -> [String] {
        do {
            guard let data = vcJsonString.data(using: .utf8),
                  let vcJsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                return []
            }

            let renderMethodArray = SvgHelper.parseRenderMethod(vcJsonObject)

            var results: [String] = []

            for case let renderMethod as [String: Any] in renderMethodArray {
                let svgTemplate = SvgHelper.extractSvgTemplate(renderMethod: renderMethod, vcJsonString: vcJsonString)

                if !svgTemplate.isEmpty {
                    let renderProperties = (renderMethod["template"] as? [String: Any])?["renderProperty"] as? [String]

                    let renderedSvg = JsonPointerResolver.replacePlaceholders(
                        svgTemplate: svgTemplate,
                        vcJson: vcJsonObject,
                        renderProperties: renderProperties
                    )
                    results.append(renderedSvg)
                }
            }

            return results
        } catch {
            print("Error in renderSvg: \(error)")
            return []
        }
    }
}
