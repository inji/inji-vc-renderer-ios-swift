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
       wellKnownJson: Optional well-known JSON.
       vcJsonString: The Verifiable Credential as a JSON string.
        
                 
     - Returns: A list of rendered SVG strings. Empty list if no valid render methods found or on error.  Return is List<Any> to accommodate future extensions.
     */
    public func generateCredentialDisplayContent(credentialFormat: CredentialFormat, wellKnownJson: String? = nil, vcJsonString: String) throws -> [Any] {
        
        guard credentialFormat == .ldp_vc else {
            throw UnsupportedCredentialFormat(
                traceabilityId: traceabilityId,
                className: String(describing: InjiVcRenderer.self)
            )
        }
        let templateHelper = TemplateHelper(traceabilityId: traceabilityId)
        let jsonPointerResolver = JsonPointerResolver(traceabilityId: traceabilityId)

        let vcJsonObject = try templateHelper.parseVcJson(vcJsonString: vcJsonString)
        let renderMethodArray = try templateHelper.parseRenderMethod(vcJsonObject)
        
        
        return try renderMethodArray.flatMap { renderMethodElement -> [String] in
            let svgList = try templateHelper.extractSVG(
                        renderMethod: renderMethodElement,
                        vcJsonString: vcJsonString
                    )

                    return try svgList.map { rawSvg in
                        try jsonPointerResolver.replaceSvgPlaceholders(
                            svgTemplate: rawSvg,
                            vcJson: vcJsonObject,
                            renderMethodElement: renderMethodElement,
                            vcJsonString: vcJsonString
                        )
                    }
                }
       }
    
   }
