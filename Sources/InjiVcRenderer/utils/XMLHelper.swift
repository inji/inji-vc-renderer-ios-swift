import Foundation
import AEXML

enum VcRendererExceptions: Error {
    case pageSetParsingException(traceabilityId: String, className: String, message: String)
}

public class XMLHelper {
    private let traceabilityId: String

    public init(traceabilityId: String) {
        self.traceabilityId = traceabilityId
    }

    public func getSVGListFromPageSet(xml: String) throws -> [String] {
        do {
            let data = xml.data(using: .utf8)!
            let document = try AEXMLDocument(xml: data)

            try validatePageSetRoot(document: document)
            
            guard let pages = document.root["page"].all, !pages.isEmpty else {
                throw VcRendererExceptions.pageSetParsingException(
                    traceabilityId: traceabilityId,
                    className: String(describing: type(of: self)),
                    message: "<pageSet> must contain at least one <page> element"
                )
            }

            var svgList: [String] = []
            for (index, page) in pages.enumerated() {
                let svgNode = page["svg"].xml

                svgList.append(svgNode)
            }

            return svgList

        } catch let error as VcRendererExceptions {
            throw error
        } catch {
            throw VcRendererExceptions.pageSetParsingException(
                traceabilityId: traceabilityId,
                className: String(describing: type(of: self)),
                message: error.localizedDescription
            )
        }
    }

    private func validatePageSetRoot(document: AEXMLDocument) throws {
        if document.root.name.caseInsensitiveCompare("pageSet") != .orderedSame {
            throw VcRendererExceptions.pageSetParsingException(
                traceabilityId: traceabilityId,
                className: String(describing: type(of: self)),
                message: "Root element must be <PageSet>"
            )
        }
    }
}
