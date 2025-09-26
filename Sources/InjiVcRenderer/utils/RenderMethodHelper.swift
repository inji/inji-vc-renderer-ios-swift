import Foundation

class RenderMethodHelper {
    private let traceabilityId: String
    private let className = String(describing: RenderMethodHelper.self)
    
    init(traceabilityId: String) {
        self.traceabilityId = traceabilityId
    }
    
    func parseRenderMethod(_ jsonObject: [String: Any]) throws -> [[String: Any]] {
        guard let renderMethodValue = jsonObject[Constants.RENDER_METHOD] else {
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
        let renderSuite = renderMethod[Constants.RENDER_SUITE] as? String ?? ""
        return renderSuite == Constants.SVG_MUSTACHE
    }
    
    private func isTemplateRenderMethodType(_ renderMethod: [String: Any]) -> Bool {
        let type = renderMethod[Constants.TYPE] as? String ?? ""
        return type == Constants.TEMPLATE_RENDER_METHOD
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
