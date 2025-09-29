import Foundation

enum ContentType: String {
    case svg = "image/svg+xml"
    case xml = "application/xml"

    static func fromType(
        mimeType: String?,
        traceabilityId: String,
        className: String?
    ) throws -> ContentType {
        guard let mimeType = mimeType else {
            throw SvgFetchException(
                traceabilityId: traceabilityId,
                className: className ?? "UnknownClass",
                exceptionMessage:  "Missing Content-Type header"
            )
        }

        if let contentType = ContentType.allCases.first(where: { $0.rawValue.caseInsensitiveCompare(mimeType) == .orderedSame }) {
            return contentType
        }
        
        throw SvgFetchException(
            traceabilityId: traceabilityId,
            className: className ?? "UnknownClass",
            exceptionMessage:  "Unsupported content type: \(mimeType)"
        )
    }
}

extension ContentType: CaseIterable {}
