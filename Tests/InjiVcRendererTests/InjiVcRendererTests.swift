import XCTest

@testable import InjiVcRenderer
import XCTest

// Mock NetworkHandler for testing
class MockNetworkManager: NetworkManager {
    override func fetchSvgAsText(url: String) -> String {
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
        default:
            return "<svg>default</svg>"
        }
    }
}

final class InjiVcRendererTests: XCTestCase {
    var renderer: InjiVcRenderer!

    override func setUp() {
        super.setUp()
        // Inject the mock into SvgHelper
        SvgHelper.networkHandler = MockNetworkManager()
        renderer = InjiVcRenderer()
    }

    override func tearDown() {
        renderer = nil
        super.tearDown()
    }

    func testHandlesMissingRenderMethod() {
        let result = renderer.renderSvg(vcJsonString: "{}")
        XCTAssertTrue(result.isEmpty)
    }

    func testHandlesInvalidJsonInput() {
        let vcJsonString = #"{ "renderMethod": [ "invalid" ] }"#
        let result = renderer.renderSvg(vcJsonString: vcJsonString)
        XCTAssertTrue(result.isEmpty)
    }

    func testHandlesWithoutRenderMethodField() {
        let vcJsonString = #"{"someField": "someValue"}"#
        let result = renderer.renderSvg(vcJsonString: vcJsonString)
        XCTAssertEqual(result, [])
    }

    func testHandlesWithRenderMethodAsEmptyObject() {
        let vcJsonString = #"{ "renderMethod": { } }"#
        let result = renderer.renderSvg(vcJsonString: vcJsonString)
        XCTAssertEqual(result, [])
    }

    func testHandlesWithRenderMethodAsEmptyArray() {
        let vcJsonString = #"{ "renderMethod": [] }"#
        let result = renderer.renderSvg(vcJsonString: vcJsonString)
        XCTAssertEqual(result, [])
    }

    func testHandlesInvalidRenderSuite() {
        let vcJsonString = #"{ "renderMethod": [ { "type": "TemplateRenderMethod", "renderSuite": "invalid-suite" } ] }"#
        let result = renderer.renderSvg(vcJsonString: vcJsonString)
        XCTAssertEqual(result, [])
    }

    func testHandlesInvalidType() {
        let vcJsonString = #"{ "renderMethod": [ { "type": "invalid", "renderSuite": "svg-mustache" } ] }"#
        let result = renderer.renderSvg(vcJsonString: vcJsonString)
        XCTAssertEqual(result, [])
    }

    func testHandlesRenderMethodAsJsonWithInvalidSuite() {
        let vcJsonString = #"{ "renderMethod": { "type": "TemplateRenderMethod", "renderSuite": "invalid-suite" } }"#
        let result = renderer.renderSvg(vcJsonString: vcJsonString)
        XCTAssertEqual(result, [])
    }

    func testHandlesRenderMethodAsJsonWithInvalidType() {
        let vcJsonString = #"{ "renderMethod": { "type": "invalid", "renderSuite": "svg-mustache" } }"#
        let result = renderer.renderSvg(vcJsonString: vcJsonString)
        XCTAssertEqual(result, [])
    }

    func testReplaceAddressFieldsWithLocale() {
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
        let result = renderer.renderSvg(vcJsonString: vcJson)
        XCTAssertEqual(result, [
            "<svg>Address : TEST_ADDRESS_LINE_1eng****TEST_REGIONeng****TEST_CITYeng***</svg>"
        ])
    }

    func testRenderMethodAsObjectHostedSvg() {
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
        let result = renderer.renderSvg(vcJsonString: vcJsonString)
        XCTAssertEqual(result, ["<svg>Email: test@gmail.com, Mobile: 1234567890</svg>"])
    }

    func testRenderMethodAsArrayMultipleHostedSvg() {
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
        let result = renderer.renderSvg(vcJsonString: vcJsonString)
        XCTAssertEqual(result, [
            "<svg>Email: test@gmail.com, Mobile: John Doe</svg>",
            "<svg>Full Name - John Doe,முழுப் பெயர் - ஜான் டோ</svg>"
        ])
    }

    func testRenderWithRenderProperty() {
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
        let result = renderer.renderSvg(vcJsonString: vcJsonString)
        XCTAssertEqual(result, ["<svg>Email: test@test.com, Mobile: -</svg>"])
    }
}
