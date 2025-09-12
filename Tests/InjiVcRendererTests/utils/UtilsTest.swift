import XCTest

@testable import InjiVcRenderer

final class UtilsTest: XCTestCase {
    private let traceId = "test-id"
    private let svgSample = "<svg>Email: {{/credentialSubject/email}}, Mobile: {{/credentialSubject/mobile}}</svg>"
    
    func testGenerateDigestMutlibase_should_return_string_starts_with_u() throws {
        let digest = try TestUtils.generateDigestMultibase(svgString: svgSample)
        print("digest: $digest")
        XCTAssertTrue(digest.starts(with: "u"), "Digest must start with 'u'")
        
    }
    
    func testValidateDigestMutlibase_should_return_true_for_correct_digest() throws {
        let digest = "uEiCi0x0IkXhQiFxa2wdnrJL02byQYoLKjN4o9_jHxh1shw"
        let result = try Utils.validateDigestMultibase(traceabilityId: traceId, svgString: svgSample, digestMultibase: digest)
        XCTAssertTrue(result, "Validation should succeed for correct digest")
        
    }
    
    func testValidateDigestMutlibase_should_return_false_for_incorrect_digest() throws {
        let digest = "uEiDc1-CXqeAP2klpU-FcUFH5etlFW2Za-aOyY221sRfcug"
        let result = try Utils.validateDigestMultibase(traceabilityId: traceId, svgString: svgSample, digestMultibase: digest)
        XCTAssertFalse(result, "Validation should fail for incorrect digest")
        
    }
    
    func testValidateDigestMutlibase_should_throw_exception_when_digest_not_starts_with_u() throws {
        let digest = "xInvalidDigest"
        XCTAssertThrowsError(
            try Utils.validateDigestMultibase(traceabilityId: traceId, svgString: svgSample, digestMultibase: digest)
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
            try Utils.validateDigestMultibase(traceabilityId: traceId, svgString: svgSample, digestMultibase: digest)
        ) { error in
            guard let vcError = error as? MultibaseValidationException else {
                XCTFail("Expected MultibaseValidationException, got \(error)")
                return
            }
            XCTAssertEqual(vcError.errorCode, VcRendererErrorCodes.multibaseValidationFailed)
            XCTAssertTrue(vcError.message.contains("Invalid multihash length"))
        }
    }
    
    
}
