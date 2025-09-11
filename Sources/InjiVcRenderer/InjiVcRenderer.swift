import Foundation

public class InjiVcRenderer {
    
    private let traceabilityId: String
    
    public init(traceabilityId: String) {
        self.traceabilityId = traceabilityId
    }
    /**
     Renders SVG templates defined in the VC's renderMethod section.
     Supports fetching templates from URLs and data URIs.
     Replaces placeholders in the templates with values from the VC JSON.

     - Parameter
       credentialFormat The format of the credential. Currently only LDP_VC is supported.
       wellKnownJson: Optional well-known JSON for additional placeholders for labels.
       vcJsonString: The Verifiable Credential as a JSON string.
        
                 
     - Returns: A list of rendered SVG strings. Empty list if no valid render methods found or on error.  Return is List<Any> to accommodate future extensions.
     */
    public func renderVC(credentialFormat: CredentialFormat, wellKnownJson: String? = nil, vcJsonString: String) throws -> [Any] {
        
        guard credentialFormat == .ldp_vc else {
            throw UnsupportedCredentialFormat(
                traceabilityId: traceabilityId,
                className: String(describing: InjiVcRenderer.self)
            )
        }
        
        
        var wellKnownJsonObject: [String: Any] = [:]
        
        if let wellKnownJson = wellKnownJson,
           let wkData = wellKnownJson.data(using: .utf8),
           let wkNode = try? JSONSerialization.jsonObject(with: wkData) as? [String: Any] {
            wellKnownJsonObject = wkNode
        }
        
        

        let vcJsonObject = try parseVcJson(vcJsonString: vcJsonString)

        let renderMethodArray = try Utils.parseRenderMethod(vcJsonObject, traceabilityId: traceabilityId)
        
        var results: [String] = []

        for case let renderMethod in renderMethodArray {
            var svgTemplate = try Utils.extractSvgTemplate(renderMethod: renderMethod, vcJsonString: vcJsonString, traceabilityId: traceabilityId)
                   
                    //// Replace label placeholders first (using well-known JSON)
                     svgTemplate = try JsonPointerResolver.replacePlaceholders(
                         svgTemplate: svgTemplate,
                         inputJson: wellKnownJsonObject,
                         traceabilityId: traceabilityId,
                         isLabelPlaceholder: true
                     )
            
            
                    //// Replace value placeholders using Vc Json
            
                   let renderProperties = (renderMethod[Constants.TEMPLATE] as? [String: Any])?[Constants.RENDER_PROPERTY] as? [String]
                   
                   let renderedSvg = try JsonPointerResolver.replacePlaceholders(
                       svgTemplate: svgTemplate,
                       inputJson: vcJsonObject,
                       renderProperties: renderProperties,
                       traceabilityId: traceabilityId
                   )
                   
                   results.append(renderedSvg)
               }
               
               return results
       }
    
    private func parseVcJson(vcJsonString: String) throws -> [String: Any] {
        do {
            guard let data = vcJsonString.data(using: .utf8) else {
                throw VcRendererException(
                    errorCode: VcRendererErrorCodes.invalidRenderMethod,
                    message: "Invalid JSON input (data encoding failed)",
                    className: String(describing: InjiVcRenderer.self),
                    traceabilityId: traceabilityId
                )
            }
            
            guard let parsed = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                throw VcRendererException(
                    errorCode: VcRendererErrorCodes.invalidRenderMethod,
                    message: "Invalid JSON input (not a dictionary)",
                    className: String(describing: InjiVcRenderer.self),
                    traceabilityId: traceabilityId
                )
            }
            
            return parsed
        } catch {
            throw VcRendererException(
                errorCode: VcRendererErrorCodes.invalidRenderMethod,
                message: "Invalid JSON input (\(error.localizedDescription))",
                className: String(describing: InjiVcRenderer.self),
                traceabilityId: traceabilityId
            )
        }
    }
   }
