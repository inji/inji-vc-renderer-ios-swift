class VcRendererException: Error, CustomStringConvertible {
    let errorCode: String
    let message: String
    let className: String
    let traceabilityId: String

    init(errorCode: String, message: String, className: String, traceabilityId: String) {
        self.errorCode = errorCode
        self.message = message
        self.className = className
        self.traceabilityId = traceabilityId

        // Simple log (instead of java.util.logging)
        print("ERROR [\(errorCode)] - \(message) | Class: \(className) | TraceabilityId: \(traceabilityId)")
    }

    var description: String {
        return "\(errorCode) : \(message)"
    }
}

class InvalidRenderSuiteException: VcRendererException {
    init(traceabilityId: String, className: String?) {
        super.init(
            errorCode: VcRendererErrorCodes.invalidRenderSuite,
            message: "Render suite must be '\(Constants.SVG_MUSTACHE)'",
            className: className ?? "",
            traceabilityId: traceabilityId
        )
    }
}

class InvalidRenderMethodTypeException: VcRendererException {
    init(traceabilityId: String, className: String?) {
        super.init(
            errorCode: VcRendererErrorCodes.invalidRenderMethodType,
            message: "Render method type must be '\(Constants.TEMPLATE_RENDER_METHOD)'",
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
