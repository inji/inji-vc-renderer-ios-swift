import XCTest

@testable import InjiVcRenderer
import XCTest

// Mock NetworkHandler for testing
class MockNetworkManager: NetworkManager {
    override func fetchSvgAsText(url: String, traceabilityId: String) -> String {
        switch url {
        case _ where url.contains("normal.svg"):
            return "<svg>Email: {{/credentialSubject/email}}, Mobile: {{/credentialSubject/mobile}}</svg>"
        case _ where url.contains("arrays.svg"):
            return "<svg>Benefits: {{/credentialSubject/benefits/0}}, {{/credentialSubject/benefits/1}}</svg>"
        case _ where url.contains("with-locale-object.svg"):
            return "<svg>Full Name - {{/credentialSubject/fullName/en}},முழுப் பெயர் - {{/credentialSubject/fullName/tam}}</svg>"
        case _ where url.contains("with-locale-as-array-of-object.svg"):
            return "<svg>Full Name - {{/credentialSubject/fullName/0/value}},முழுப் பெயர் - {{/credentialSubject/fullName/1/value}}</svg>"
        case _ where url.contains("nested-object.svg"):
            return "<svg>Address : {{/credentialSubject/addressLine1/0/value}}****{{/credentialSubject/region/0/value}}****{{/credentialSubject/city/0/value}}***</svg>"
        case _ where url.contains("qrcode.svg"):
            return "<svg>QR code : <image id = \"qrCodeImage\" xlink:href{{/qrCodeImage}}</svg>"
        case _ where url.contains("multilingual.svg"):
            return "<svg>" +
            "{{/credential_definition/credentialSubject/fullName/display/0/name}}: {{/credentialSubject/fullName/0/value}}," +
            "{{/credential_definition/credentialSubject/fullName/display/1/name}}: {{/credentialSubject/fullName/1/value}}" +
            "</svg>"
        default:
            return "<svg>default</svg>"
        }
    }
}

final class InjiVcRendererTests: XCTestCase {
    var renderer: InjiVcRenderer!
    
    let traceabilityId = "test-id"

    override func setUp() {
        super.setUp()
        // Inject the mock into Utils
        Utils.networkHandler = MockNetworkManager()
        renderer = InjiVcRenderer(traceabilityId: traceabilityId)
    }

    override func tearDown() {
        renderer = nil
        super.tearDown()
    }
    
    func testParseVcJson_Unsupported_CredentialFormat() {
        let invalidJson = #"{"name": }"#
        
        XCTAssertThrowsError(try renderer.renderVC(credentialFormat : CredentialFormat.fromValue("mso_mdoc"), vcJsonString: invalidJson)) { error in
            guard let vcError = error as? VcRendererException else {
                XCTFail("Expected VcRendererException but got \(error)")
                return
            }
            XCTAssertEqual(vcError.errorCode, VcRendererErrorCodes.unsupportedCredentialFormat)
            XCTAssertTrue(vcError.message.contains("Only LDP_VC credential format is supported"))
        }
    }
    
    func testParseVcJson_Supported_CredentialFormat() throws {
        let vcJsonString = """
        {
            "credentialSubject": {
                "email": "test@gmail.com",
                "mobile": "1234567890"
            },
            "renderMethod": {
                "type": "TemplateRenderMethod",
                "renderSuite": "svg-mustache",
                "template": {
                    "id": "https://degree.example/credential-templates/normal.svg",
                    "mediaType": "image/svg+xml",
                    "digestMultibase": "xyz"
                }
            }
        }
        """
        let resultAny = try renderer.renderVC(credentialFormat : CredentialFormat.fromValue("ldp_vc"), vcJsonString: vcJsonString)
        let result = resultAny.compactMap { $0 as? String }
        XCTAssertEqual(result, ["<svg>Email: test@gmail.com, Mobile: 1234567890</svg>"])
    }
     
     func testParseVcJson_InvalidJson_Throws() {
         let invalidJson = #"{"name": }"# 
         
         XCTAssertThrowsError(try renderer.renderVC(credentialFormat : .ldp_vc, vcJsonString: invalidJson)) { error in
             guard let vcError = error as? VcRendererException else {
                 XCTFail("Expected VcRendererException but got \(error)")
                 return
             }
             XCTAssertEqual(vcError.errorCode, VcRendererErrorCodes.invalidRenderMethod)
             XCTAssertTrue(vcError.message.contains("Invalid JSON input"))
         }
     }


    func testHandlesMissingRenderMethod() {
        XCTAssertThrowsError(try renderer.renderVC(credentialFormat : .ldp_vc, vcJsonString: "{}")) { error in
            assertVcRendererException(error,
                       expectedMessage: "RenderMethod object is invalid",
                                      expectedCode: VcRendererErrorCodes.invalidRenderMethod
                   )
        }
    }

    func testHandlesInvalidJsonInput() {
        let vcJsonString = #"{ "renderMethod": [ "invalid" ] }"#
        XCTAssertThrowsError(try renderer.renderVC(credentialFormat : .ldp_vc, vcJsonString: vcJsonString)) { error in
            assertVcRendererException(error,
                       expectedMessage: "RenderMethod object is invalid",
                                      expectedCode: VcRendererErrorCodes.invalidRenderMethod
                   )
        }
    }

    func testHandlesWithoutRenderMethodField() {
        let vcJsonString = #"{"someField": "someValue"}"#
        XCTAssertThrowsError(try renderer.renderVC(credentialFormat : .ldp_vc, vcJsonString: vcJsonString)) { error in
            assertVcRendererException(error,
                       expectedMessage: "RenderMethod object is invalid",
                                      expectedCode: VcRendererErrorCodes.invalidRenderMethod
                   )
        }
    }

    func testHandlesWithRenderMethodAsEmptyObject() {
        let vcJsonString = #"{ "renderMethod": { } }"#
        XCTAssertThrowsError(try renderer.renderVC(credentialFormat : .ldp_vc, vcJsonString: vcJsonString)) { error in
            assertVcRendererException(error,
                       expectedMessage: "RenderMethod object is invalid",
                                      expectedCode: VcRendererErrorCodes.invalidRenderMethod
                   )
        }
    }

    func testHandlesWithRenderMethodAsEmptyArray() {
        let vcJsonString = #"{ "renderMethod": [] }"#
        XCTAssertThrowsError(try renderer.renderVC(credentialFormat : .ldp_vc, vcJsonString: vcJsonString)) { error in
            assertVcRendererException(error,
                       expectedMessage: "RenderMethod object is invalid",
                                      expectedCode: VcRendererErrorCodes.invalidRenderMethod
                   )
        }
    }

    func testHandlesInvalidRenderSuite() {
        let vcJsonString = #"{ "renderMethod": [ { "type": "TemplateRenderMethod", "renderSuite": "invalid-suite" } ] }"#
        XCTAssertThrowsError(try renderer.renderVC(credentialFormat : .ldp_vc, vcJsonString: vcJsonString)) { error in
            assertVcRendererException(error,
                       expectedMessage: "Render suite must be '\(Constants.SVG_MUSTACHE)'",
                                      expectedCode: VcRendererErrorCodes.invalidRenderSuite
                   )
        }
    }

    func testHandlesInvalidType() {
        let vcJsonString = #"{ "renderMethod": [ { "type": "invalid", "renderSuite": "svg-mustache" } ] }"#
        XCTAssertThrowsError(try renderer.renderVC(credentialFormat : .ldp_vc, vcJsonString: vcJsonString)) { error in
            assertVcRendererException(error,
                       expectedMessage: "Render method type must be '\(Constants.TEMPLATE_RENDER_METHOD)'",
                                      expectedCode: VcRendererErrorCodes.invalidRenderMethodType
                   )
        }
    }

    func testHandlesRenderMethodAsJsonWithInvalidSuite() {
        let vcJsonString = #"{ "renderMethod": { "type": "TemplateRenderMethod", "renderSuite": "invalid-suite" } }"#
        XCTAssertThrowsError(try renderer.renderVC(credentialFormat : .ldp_vc, vcJsonString: vcJsonString)) { error in
            assertVcRendererException(error,
                       expectedMessage: "Render suite must be '\(Constants.SVG_MUSTACHE)'",
                                      expectedCode: VcRendererErrorCodes.invalidRenderSuite
                   )
        }
    }

    func testHandlesRenderMethodAsJsonWithInvalidType() {
        let vcJsonString = #"{ "renderMethod": { "type": "invalid", "renderSuite": "svg-mustache" } }"#
        XCTAssertThrowsError(try renderer.renderVC(credentialFormat : .ldp_vc, vcJsonString: vcJsonString)) { error in
            assertVcRendererException(error,
                       expectedMessage: "Render method type must be '\(Constants.TEMPLATE_RENDER_METHOD)'",
                                      expectedCode: VcRendererErrorCodes.invalidRenderMethodType
                   )
        }
    }
    
    func testMissingTemplateID()  {
        let vcJson = """
        {
            "credentialSubject": {
                "addressLine1": [
                    { "language": "eng", "value": "TEST_ADDRESS_LINE_1eng" },
                    { "language": "fr", "value": "TEST_ADDRESS_LINE_1fr" }
                ],
                "city": [ { "language": "eng", "value": "TEST_CITYeng" } ],
                "region": [ { "language": "eng", "value": "TEST_REGIONeng" } ],
                "postalCode": [ { "language": "eng", "value": "TEST_POSTAL_CODEeng" } ]
            },
            "renderMethod": {
                "type": "TemplateRenderMethod",
                "renderSuite": "svg-mustache",
                "template": {
                    "mediaType": "image/svg+xml",
                    "digestMultibase": "xyz"
                }
            }
        }
        """
        XCTAssertThrowsError(try renderer.renderVC(credentialFormat : .ldp_vc, vcJsonString: vcJson)) { error in
            assertVcRendererException(error,
                       expectedMessage: "Template ID is missing in renderMethod",
                                      expectedCode: VcRendererErrorCodes.missingTemplateId
                   )
        }
    }

    func testReplaceAddressFieldsWithLocale() throws {
        let vcJson = """
        {
            "credentialSubject": {
                "addressLine1": [
                    { "language": "eng", "value": "TEST_ADDRESS_LINE_1eng" },
                    { "language": "fr", "value": "TEST_ADDRESS_LINE_1fr" }
                ],
                "city": [ { "language": "eng", "value": "TEST_CITYeng" } ],
                "region": [ { "language": "eng", "value": "TEST_REGIONeng" } ],
                "postalCode": [ { "language": "eng", "value": "TEST_POSTAL_CODEeng" } ]
            },
            "renderMethod": {
                "type": "TemplateRenderMethod",
                "renderSuite": "svg-mustache",
                "template": {
                    "id": "https://degree.example/credential-templates/nested-object.svg",
                    "mediaType": "image/svg+xml",
                    "digestMultibase": "xyz"
                }
            }
        }
        """
        let resultAny = try renderer.renderVC(credentialFormat : .ldp_vc, vcJsonString: vcJson)
        let result = resultAny.compactMap { $0 as? String }
        XCTAssertEqual(result, [
            "<svg>Address : TEST_ADDRESS_LINE_1eng****TEST_REGIONeng****TEST_CITYeng***</svg>"
        ])
    }

    func testRenderMethodAsObjectHostedSvg() throws {
        let vcJsonString = """
        {
            "credentialSubject": {
                "email": "test@gmail.com",
                "mobile": "1234567890"
            },
            "renderMethod": {
                "type": "TemplateRenderMethod",
                "renderSuite": "svg-mustache",
                "template": {
                    "id": "https://degree.example/credential-templates/normal.svg",
                    "mediaType": "image/svg+xml",
                    "digestMultibase": "xyz"
                }
            }
        }
        """
        let resultAny = try renderer.renderVC(credentialFormat : .ldp_vc, vcJsonString: vcJsonString)
        let result = resultAny.compactMap { $0 as? String }
        XCTAssertEqual(result, ["<svg>Email: test@gmail.com, Mobile: 1234567890</svg>"])
    }

    func testRenderMethodAsArrayMultipleHostedSvg() throws {
        let vcJsonString = """
        {
            "credentialSubject": {
                "mobile": "John Doe",
                "email": "test@gmail.com",
                "fullName": { "en": "John Doe", "tam": "ஜான் டோ" }
            },
            "renderMethod": [
                {
                    "type": "TemplateRenderMethod",
                    "renderSuite": "svg-mustache",
                    "template": {
                        "id": "https://degree.example/credential-templates/normal.svg",
                        "mediaType": "image/svg+xml",
                        "digestMultibase": "xyz"
                    }
                },
                {
                    "type": "TemplateRenderMethod",
                    "renderSuite": "svg-mustache",
                    "template": {
                        "id": "https://degree.example/credential-templates/with-locale-object.svg",
                        "mediaType": "image/svg+xml",
                        "digestMultibase": "xyz"
                    }
                }
            ]
        }
        """
        let resultAny = try renderer.renderVC(credentialFormat : .ldp_vc, vcJsonString: vcJsonString)
        let result = resultAny.compactMap { $0 as? String }
        XCTAssertEqual(result, [
            "<svg>Email: test@gmail.com, Mobile: John Doe</svg>",
            "<svg>Full Name - John Doe,முழுப் பெயர் - ஜான் டோ</svg>"
        ])
    }

    func testRenderWithRenderProperty() throws {
        let vcJsonString = """
        {
            "issuer": "Example University",
            "validFrom": "2023-01-01",
            "credentialSubject": {
                "fullName": "John Doe",
                "name": "Tester",
                "email": "test@test.com"
            },
            "renderMethod": {
                "type": "TemplateRenderMethod",
                "renderSuite": "svg-mustache",
                "template": {
                    "id": "https://degree.example/credential-templates/normal.svg",
                    "mediaType": "image/svg+xml",
                    "digestMultibase": "xyz",
                    "renderProperty": [ "/issuer", "/credentialSubject/email", "/credentialSubject/degree/name" ]
                }
            }
        }
        """
        let resultAny = try renderer.renderVC(credentialFormat : .ldp_vc, vcJsonString: vcJsonString)
        let result = resultAny.compactMap { $0 as? String }
        XCTAssertEqual(result, ["<svg>Email: test@test.com, Mobile: -</svg>"])
    }
    
    func testWithWellknownAndLabelPlaceholderPresentInSvg() throws {
        let vcJsonString = """
        {
            "credentialSubject": {
                "fullName": [
                    {
                        "language": "eng",
                        "value": "John Doe"
                    },
                    {
                        "language": "tam",
                        "value": "ஜான் டோ"
                    }
                ],
                "mobile": "1234567890"
            },
            "renderMethod": {
                "type": "TemplateRenderMethod",
                "renderSuite": "svg-mustache",
                  "template": {
                    "id": "https://degree.example/credential-templates/multilingual.svg",
                    "mediaType": "image/svg+xml",
                    "digestMultibase": "zQmerWC85Wg6wFl9znFCwYxApG270iEu5h6JqWAPdhyxz2dR"
                  }
              }
          }
        """
        
        let wellknownJsonString = """
         {
            "credential_definition": {
              "type": [
                "FarmerCredential_WithFace",
                "VerifiableCredential"
              ],
              "credentialSubject": {
                "fullName": {
                      "display": [
                         {
                            "language": "eng",
                            "name": "Full Name"
                        },
                        {
                            "language": "tam",
                            "name": "முழுப் பெயர்"
                        }
                      ]
                }
              }
            }
          }
        """
        let resultAny = try renderer.renderVC(credentialFormat : .ldp_vc, wellKnownJson: wellknownJsonString, vcJsonString: vcJsonString)
        let result = resultAny.compactMap { $0 as? String }
        XCTAssertEqual(result, ["<svg>" +
                                "Full Name: John Doe," +
                                "முழுப் பெயர்: ஜான் டோ" +
                                "</svg>"])
    }
    
    func testWithoutWellknownAndLabelPlaceholderPresentInSvg() throws {
        let vcJsonString = """
         {
            "credentialSubject": {
                "fullName": [
                    {
                        "language": "eng",
                        "value": "John Doe"
                    },
                    {
                        "language": "tam",
                        "value": "ஜான் டோ"
                    }
                ],
                "mobile": "1234567890"
            },
            "renderMethod": {
                "type": "TemplateRenderMethod",
                "renderSuite": "svg-mustache",
                  "template": {
                    "id": "https://degree.example/credential-templates/multilingual.svg",
                    "mediaType": "image/svg+xml",
                    "digestMultibase": "zQmerWC85Wg6wFl9znFCwYxApG270iEu5h6JqWAPdhyxz2dR"
                  }
              }
          }
        """
        
    
        let resultAny = try renderer.renderVC(credentialFormat : .ldp_vc, vcJsonString: vcJsonString)
        let result = resultAny.compactMap { $0 as? String }
        XCTAssertEqual(result, ["<svg>" +
                                "Full Name: John Doe," +
                                "Full Name: ஜான் டோ" +
                                "</svg>"])
    }
}

