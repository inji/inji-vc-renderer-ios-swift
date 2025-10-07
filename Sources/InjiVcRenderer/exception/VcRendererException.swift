import Foundation

public class VcRendererException: Error, CustomStringConvertible, LocalizedError {
    public let errorCode: String
    public let message: String
    public let className: String
    private let traceabilityId: String

    init(errorCode: String, message: String, className: String, traceabilityId: String) {
        self.errorCode = errorCode
        self.message = message
        self.className = className
        self.traceabilityId = traceabilityId

        // Simple log (instead of java.util.logging)
        print("ERROR [\(errorCode)] - \(message) | Class: \(className) | TraceabilityId: \(traceabilityId)")
    }

    public var description: String {
        return "\(errorCode) : \(message)"
    }

    public var errorDescription: String? {
        return message
    }
}

class InvalidRenderSuiteException: VcRendererException {
    init(traceabilityId: String, className: String?) {
        super.init(
            errorCode: VcRendererErrorCodes.invalidRenderSuite,
            message: "Render suite must be '\(Constants.svgMustache)'",
            className: className ?? "",
            traceabilityId: traceabilityId
        )
    }
}

class InvalidRenderMethodTypeException: VcRendererException {
    init(traceabilityId: String, className: String?) {
        super.init(
            errorCode: VcRendererErrorCodes.invalidRenderMethodType,
            message: "Render method type must be '\(Constants.templateRenderMethod)'",
            className: className ?? "",
            traceabilityId: traceabilityId
        )
    }
}

class QRCodeGenerationFailureException: VcRendererException {
    init(traceabilityId: String, exceptionMessage: String? = "Unknown Error", className: String?) {
        super.init(
            errorCode: VcRendererErrorCodes.qrCodeGenerationFailure,
            message: "QR code generation failed: \(exceptionMessage)",
            className: className ?? "",
            traceabilityId: traceabilityId
        )
    }
}

class MissingTemplateIdException: VcRendererException {
    init(traceabilityId: String, className: String?) {
        super.init(
            errorCode: VcRendererErrorCodes.missingTemplateId,
            message: "Template ID is missing in renderMethod",
            className: className ?? "",
            traceabilityId: traceabilityId
        )
    }
}

class SvgFetchException: VcRendererException {
    init(traceabilityId: String, className: String?, exceptionMessage: String) {
        super.init(
            errorCode: VcRendererErrorCodes.svgFetchError,
            message: "Failed to fetch SVG: \(exceptionMessage)",
            className: className ?? "",
            traceabilityId: traceabilityId
        )
    }
}

class InvalidRenderMethodException: VcRendererException {
    init(traceabilityId: String, className: String?) {
        super.init(
            errorCode: VcRendererErrorCodes.invalidRenderMethod,
            message: "RenderMethod object is invalid",
            className: className ?? "",
            traceabilityId: traceabilityId
        )
    }
}

class UnsupportedCredentialFormat: VcRendererException {
    init(traceabilityId: String, className: String?) {
        super.init(
            errorCode: VcRendererErrorCodes.unsupportedCredentialFormat,
            message: "Only LDP_VC credential format is supported",
            className: className ?? "",
            traceabilityId: traceabilityId
        )
    }
}

class MultibaseValidationException: VcRendererException {
    init(traceabilityId: String, className: String?, exceptionMessage: String) {
        super.init(
            errorCode: VcRendererErrorCodes.multibaseValidationFailed,
            message: "Multibase validation failed: \(exceptionMessage)",
            className: className ?? "",
            traceabilityId: traceabilityId
        )
    }
}

class PageSetParsingException: VcRendererException {
    init(traceabilityId: String, className: String?, exceptionMessage: String) {
        super.init(
            errorCode: VcRendererErrorCodes.xmlParsingFailed,
            message: "Error while parsing the Pageset XML: \(exceptionMessage)",
            className: className ?? "",
            traceabilityId: traceabilityId
        )
    }
}
