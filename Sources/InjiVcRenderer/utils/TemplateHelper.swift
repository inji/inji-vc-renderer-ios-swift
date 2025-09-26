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

        try RenderMethodHelper(traceabilityId: traceabilityId).validateSvgMustacheRenderSuite(renderMethod)
        try RenderMethodHelper(traceabilityId: traceabilityId).validateTemplateRenderMethodType(renderMethod)

        guard let templateValue = renderMethod[Constants.TEMPLATE] as? [String: Any] else {
            throw InvalidRenderMethodException(traceabilityId: traceabilityId, className: className)
        }

        guard let templateId = templateValue[Constants.ID] as? String else {
            throw MissingTemplateIdException(traceabilityId: traceabilityId, className: className)
        }

        var templateResponse: TemplateResponse
           do {
               templateResponse = try TemplateHelper.networkHandler.fetch(url: templateId, traceabilityId: traceabilityId)
           } catch {
               throw SvgFetchException(traceabilityId: traceabilityId, className: className, exceptionMessage: error.localizedDescription)
           }
        let digestMultibase = templateValue[Constants.DIGEST_MULTIBASE] as? String
        if let digestMultibase = digestMultibase,
           try !DigestMultibaseHelper(traceabilityId: traceabilityId).validateDigestMultibase(svgString: templateResponse.body, digestMultibase: digestMultibase) {
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
    
}
