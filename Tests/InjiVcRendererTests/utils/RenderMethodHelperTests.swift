import XCTest
@testable import InjiVcRenderer

final class RenderMethodHelperTests: XCTestCase {
    private var helper: RenderMethodHelper!
    private let traceabilityId = "test-trace-id"

    override func setUp() {
        super.setUp()
        helper = RenderMethodHelper(traceabilityId: traceabilityId)
    }


    func testParseRenderMethod_validArray() throws {
        let input: [String: Any] = [
            Constants.RENDER_METHOD: [
                [Constants.RENDER_SUITE: Constants.SVG_MUSTACHE]
            ]
        ]

        let result = try helper.parseRenderMethod(input)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0][Constants.RENDER_SUITE] as? String, Constants.SVG_MUSTACHE)
    }

    func testParseRenderMethod_validDict() throws {
        let input: [String: Any] = [
            Constants.RENDER_METHOD: [Constants.TYPE: Constants.TEMPLATE_RENDER_METHOD]
        ]

        let result = try helper.parseRenderMethod(input)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0][Constants.TYPE] as? String, Constants.TEMPLATE_RENDER_METHOD)
    }

    func testParseRenderMethod_missingKey() {
        let input: [String: Any] = [:]

        XCTAssertThrowsError(try helper.parseRenderMethod(input)) { error in
            XCTAssertTrue(error is InvalidRenderMethodException)
        }
    }

    func testParseRenderMethod_emptyArray() {
        let input: [String: Any] = [Constants.RENDER_METHOD: []]

        XCTAssertThrowsError(try helper.parseRenderMethod(input)) { error in
            XCTAssertTrue(error is InvalidRenderMethodException)
        }
    }

    func testParseRenderMethod_arrayWithEmptyDict() {
        let input: [String: Any] = [Constants.RENDER_METHOD: [[:]]]

        XCTAssertThrowsError(try helper.parseRenderMethod(input)) { error in
            XCTAssertTrue(error is InvalidRenderMethodException)
        }
    }

    func testParseRenderMethod_emptyDict() {
        let input: [String: Any] = [Constants.RENDER_METHOD: [:]]

        XCTAssertThrowsError(try helper.parseRenderMethod(input)) { error in
            XCTAssertTrue(error is InvalidRenderMethodException)
        }
    }

    func testParseRenderMethod_wrongType() {
        let input: [String: Any] = [Constants.RENDER_METHOD: "invalid"]

        XCTAssertThrowsError(try helper.parseRenderMethod(input)) { error in
            XCTAssertTrue(error is InvalidRenderMethodException)
        }
    }


    func testValidateSvgMustacheRenderSuite_valid() throws {
        let renderMethod = [Constants.RENDER_SUITE: Constants.SVG_MUSTACHE]
        XCTAssertNoThrow(try helper.validateSvgMustacheRenderSuite(renderMethod))
    }

    func testValidateSvgMustacheRenderSuite_invalid() {
        let renderMethod = [Constants.RENDER_SUITE: "other"]
        XCTAssertThrowsError(try helper.validateSvgMustacheRenderSuite(renderMethod)) { error in
            XCTAssertTrue(error is InvalidRenderSuiteException)
        }
    }


    func testValidateTemplateRenderMethodType_valid() throws {
        let renderMethod = [Constants.TYPE: Constants.TEMPLATE_RENDER_METHOD]
        XCTAssertNoThrow(try helper.validateTemplateRenderMethodType(renderMethod))
    }

    func testValidateTemplateRenderMethodType_invalid() {
        let renderMethod = [Constants.TYPE: "other"]
        XCTAssertThrowsError(try helper.validateTemplateRenderMethodType(renderMethod)) { error in
            XCTAssertTrue(error is InvalidRenderMethodTypeException)
        }
    }

    func testParseVcJson_validJson() throws {
        let json = #"{"key":"value"}"#
        let result = try helper.parseVcJson(vcJsonString: json)
        XCTAssertEqual(result["key"] as? String, "value")
    }

    func testParseVcJson_invalidJson() {
        let json = #"{"key":}"#

        XCTAssertThrowsError(try helper.parseVcJson(vcJsonString: json)) { error in
            XCTAssertTrue(error is VcRendererException)
            let e = error as! VcRendererException
            XCTAssertEqual(e.errorCode, VcRendererErrorCodes.invalidVcJson)
        }
    }

    func testParseVcJson_encodingFailure() {
        let json = ""
        XCTAssertThrowsError(try helper.parseVcJson(vcJsonString: json)) { error in
            XCTAssertTrue(error is VcRendererException)
        }
    }
}
