import Foundation

struct TemplateResponse: Equatable {
    let contentType: ContentType
    let body: String

    func isXmlTemplate() -> Bool {
        return contentType == .xml
    }
}
