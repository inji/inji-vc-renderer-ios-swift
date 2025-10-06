import XCTest

@testable import InjiVcRenderer

final class TemplateHelperTests: XCTestCase {
    private let svgSample = "<svg>Email: {{/credentialSubject/email}}, Mobile: {{/credentialSubject/mobile}}</svg>"
    private let helper = TemplateHelper(traceabilityId: "test-id")
    
    
    func testGenerateDigestMutlibase_should_return_string_starts_with_u() throws {
        let digest = try TestUtils.generateDigestMultibase(svgString: svgSample)
        print("digest: $digest")
        XCTAssertTrue(digest.starts(with: "u"), "Digest must start with 'u'")
        
    }
    
    func testValidateDigestMutlibase_should_return_true_for_correct_digest() throws {
        let digest = "uEiCi0x0IkXhQiFxa2wdnrJL02byQYoLKjN4o9_jHxh1shw"
        let result = try helper.validateDigestMultibase(svgString: svgSample, digestMultibase: digest)
        XCTAssertTrue(result, "Validation should succeed for correct digest")
        
    }
    
    func testValidateDigestMutlibase_should_return_false_for_incorrect_digest() throws {
        let digest = "uEiDc1-CXqeAP2klpU-FcUFH5etlFW2Za-aOyY221sRfcug"
        let result = try helper.validateDigestMultibase(svgString: svgSample, digestMultibase: digest)
        XCTAssertFalse(result, "Validation should fail for incorrect digest")
        
    }
    
    func testValidateDigestMutlibase_should_throw_exception_when_digest_not_starts_with_u() throws {
        let digest = "xInvalidDigest"
        XCTAssertThrowsError(
            try helper.validateDigestMultibase(svgString: svgSample, digestMultibase: digest)
        ) { error in
            guard let vcError = error as? MultibaseValidationException else {
                XCTFail("Expected MultibaseValidationException, got \(error)")
                return
            }
            XCTAssertEqual(vcError.errorCode, VcRendererErrorCodes.multibaseValidationFailed)
            XCTAssertTrue(vcError.message.contains("digestMultibase must start with 'u'"))
        }
    }
    
    func testValidateDigestMutlibase_should_throw_exception_when_digest_has_invalid_multihash_length() throws {
        let digest = "uAA"
        XCTAssertThrowsError(
            try helper.validateDigestMultibase(svgString: svgSample, digestMultibase: digest)
        ) { error in
            guard let vcError = error as? MultibaseValidationException else {
                XCTFail("Expected MultibaseValidationException, got \(error)")
                return
            }
            XCTAssertEqual(vcError.errorCode, VcRendererErrorCodes.multibaseValidationFailed)
            XCTAssertTrue(vcError.message.contains("Invalid multihash length"))
        }
    }
    func testParseRenderMethod_validArray() throws {
        let input: [String: Any] = [
            Constants.renderMethod: [
                [Constants.renderSuite: Constants.svgMustache]
            ]
        ]

        let result = try helper.parseRenderMethod(input)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0][Constants.renderSuite] as? String, Constants.svgMustache)
    }

    func testParseRenderMethod_validDict() throws {
        let input: [String: Any] = [
            Constants.renderMethod: [Constants.type: Constants.templateRenderMethod]
        ]

        let result = try helper.parseRenderMethod(input)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0][Constants.type] as? String, Constants.templateRenderMethod)
    }

    func testParseRenderMethod_missingKey() {
        let input: [String: Any] = [:]

        XCTAssertThrowsError(try helper.parseRenderMethod(input)) { error in
            XCTAssertTrue(error is InvalidRenderMethodException)
        }
    }

    func testParseRenderMethod_emptyArray() {
        let input: [String: Any] = [Constants.renderMethod: []]

        XCTAssertThrowsError(try helper.parseRenderMethod(input)) { error in
            XCTAssertTrue(error is InvalidRenderMethodException)
        }
    }

    func testParseRenderMethod_arrayWithEmptyDict() {
        let input: [String: Any] = [Constants.renderMethod: [[:]]]

        XCTAssertThrowsError(try helper.parseRenderMethod(input)) { error in
            XCTAssertTrue(error is InvalidRenderMethodException)
        }
    }

    func testParseRenderMethod_emptyDict() {
        let input: [String: Any] = [Constants.renderMethod: [:]]

        XCTAssertThrowsError(try helper.parseRenderMethod(input)) { error in
            XCTAssertTrue(error is InvalidRenderMethodException)
        }
    }

    func testParseRenderMethod_wrongType() {
        let input: [String: Any] = [Constants.renderMethod: "invalid"]

        XCTAssertThrowsError(try helper.parseRenderMethod(input)) { error in
            XCTAssertTrue(error is InvalidRenderMethodException)
        }
    }


    func testValidateSvgMustacheRenderSuite_valid() throws {
        let renderMethod = [Constants.renderSuite: Constants.svgMustache]
        XCTAssertNoThrow(try helper.validateSvgMustacheRenderSuite(renderMethod))
    }

    func testValidateSvgMustacheRenderSuite_invalid() {
        let renderMethod = [Constants.renderSuite: "other"]
        XCTAssertThrowsError(try helper.validateSvgMustacheRenderSuite(renderMethod)) { error in
            XCTAssertTrue(error is InvalidRenderSuiteException)
        }
    }


    func testValidateTemplateRenderMethodType_valid() throws {
        let renderMethod = [Constants.type: Constants.templateRenderMethod]
        XCTAssertNoThrow(try helper.validateTemplateRenderMethodType(renderMethod))
    }

    func testValidateTemplateRenderMethodType_invalid() {
        let renderMethod = [Constants.type: "other"]
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
