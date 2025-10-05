import Foundation
import AEXML

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
                throw PageSetParsingException(
                    traceabilityId: traceabilityId,
                    className: String(describing: type(of: self)),
                    exceptionMessage: "<pageSet> must contain at least one <page> element"
                )
            }

            var svgList: [String] = []
            for page in pages {
                let svgNode = page["svg"].xml

                svgList.append(svgNode)
            }

            return svgList

        } catch let error as VcRendererException {
            throw error
        } catch {
            throw PageSetParsingException(
                traceabilityId: traceabilityId,
                className: String(describing: type(of: self)),
                exceptionMessage: error.localizedDescription
            )
        }
    }

    private func validatePageSetRoot(document: AEXMLDocument) throws {
        if document.root.name.caseInsensitiveCompare("pageSet") != .orderedSame {
            throw PageSetParsingException(
                traceabilityId: traceabilityId,
                className: String(describing: type(of: self)),
                exceptionMessage: "Root element must be <PageSet>"
            )
        }
    }
}
