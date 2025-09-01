import XCTest

@testable import InjiVcRenderer

final class JsonPointerResolverTests: XCTestCase {

    func testReplaceSimpleObjectField() {
        let template = "<svg >{{/credentialSubject/gender/0/value}}##{{/credentialSubject/fullName}}</svg>"
        let json: [String: Any] = [
            "credentialSubject": [
                "gender": [
                    ["language": "eng", "value": "English Male"]
                ],
                "fullName": "John"
            ]
        ]
        let expected = "<svg >English Male##John</svg>"
        let result = JsonPointerResolver.replacePlaceholders(svgTemplate: template, vcJson : json)
        XCTAssertEqual(result, expected)
    }

    func testReplaceArrayFields() {
        let template = "<svg >{{/credentialSubject/benefits/0}}, {{/credentialSubject/benefits/1}}</svg>"
        let json: [String: Any] = [
            "credentialSubject": [
                "benefits": [
                    "Item 1 is on the list",
                    "Item 2 is on the list",
                    "Item 3 is on the list"
                ],
                "fullName": "John"
            ]
        ]
        let expected = "<svg >Item 1 is on the list, Item 2 is on the list</svg>"
        let result = JsonPointerResolver.replacePlaceholders(svgTemplate: template, vcJson : json)
        XCTAssertEqual(result, expected)
    }

    func testReplaceMissingPointerReturnsDash() {
        let template = "<svg >{{/credentialSubject/email}}##{{/credentialSubject/middleName}}</svg>"
        let json: [String: Any] = [
            "credentialSubject": [
                "gender": [["language": "eng", "value": "English Male"]],
                "fullName": "John"
            ]
        ]
        let expected = "<svg >-##-</svg>"
        let result = JsonPointerResolver.replacePlaceholders(svgTemplate: template, vcJson : json)
        XCTAssertEqual(result, expected)
    }

    func testReplaceFieldsWithLocaleAsObjects() {
        let template = "<svg>Gender: {{/credentialSubject/gender/eng}}, பாலினம் : {{/credentialSubject/gender/tam}} </svg>"
        let json: [String: Any] = [
            "credentialSubject": [
                "gender": [
                    "eng": "Male",
                    "tam": "ஆண்"
                ]
            ]
        ]
        let expected = "<svg>Gender: Male, பாலினம் : ஆண் </svg>"
        let result = JsonPointerResolver.replacePlaceholders(svgTemplate: template, vcJson : json)
        XCTAssertEqual(result, expected)
    }

    func testReplaceFieldsWithLocaleAsArrayOfObjects() {
        let template = "<svg>Gender: {{/credentialSubject/gender/0/value}}, பாலினம் : {{/credentialSubject/gender/1/value}} </svg>"
        let json: [String: Any] = [
            "credentialSubject": [
                "gender": [
                    ["language": "eng", "value": "Male"],
                    ["language": "tam", "value": "ஆண்"]
                ]
            ]
        ]
        let expected = "<svg>Gender: Male, பாலினம் : ஆண் </svg>"
        let result = JsonPointerResolver.replacePlaceholders(svgTemplate: template, vcJson : json)
        XCTAssertEqual(result, expected)
    }

    func testReplaceNestedAddressFields() {
        let template = "<svg>{{/credentialSubject/address/addressLine1/0/value}}</svg>"
        let json: [String: Any] = [
            "credentialSubject": [
                "address": [
                    "addressLine1": [
                        ["language": "eng", "value": "TEST_ADDRESS_LINE_1eng"],
                        ["language": "fr", "value": "TEST_ADDRESS_LINE_1fr"]
                    ],
                    "city": [
                        ["language": "eng", "value": "TEST_CITYeng"]
                    ]
                ]
            ]
        ]
        let expected = "<svg>TEST_ADDRESS_LINE_1eng</svg>"
        let result = JsonPointerResolver.replacePlaceholders(svgTemplate: template, vcJson : json)
        XCTAssertEqual(result, expected)
    }

    func testReplaceFieldWithSlash() {
        let template = "<svg >{{/credentialSubject/ac~1dc}}</svg>"
        let json: [String: Any] = [
            "credentialSubject": ["ac/dc": "current unit"]
        ]
        let expected = "<svg >current unit</svg>"
        let result = JsonPointerResolver.replacePlaceholders(svgTemplate: template, vcJson : json)
        XCTAssertEqual(result, expected)
    }

    func testReplaceFieldWithTilde() {
        let template = "<svg >{{/credentialSubject/a~0b}}</svg>"
        let json: [String: Any] = [
            "credentialSubject": ["a~b": "test"]
        ]
        let expected = "<svg >test</svg>"
        let result = JsonPointerResolver.replacePlaceholders(svgTemplate: template, vcJson : json)
        XCTAssertEqual(result, expected)
    }

    func testPointerToRootReturnsFullDocument() throws {
        let template = "<svg>{{}}</svg>"
        let json: [String: Any] = ["a": 1, "b": 2]
        let expected = "<svg>{\"a\":1,\"b\":2}</svg>"
        
        let result = JsonPointerResolver.replacePlaceholders(svgTemplate: template, vcJson: json)
        
        // Extract JSON portion between <svg> tags
        let resultJsonPart = result.replacingOccurrences(of: "<svg>", with: "")
                                    .replacingOccurrences(of: "</svg>", with: "")
        let expectedJsonPart = expected.replacingOccurrences(of: "<svg>", with: "")
                                       .replacingOccurrences(of: "</svg>", with: "")

        let resultObj = try JSONSerialization.jsonObject(with: Data(resultJsonPart.utf8)) as? NSDictionary
        let expectedObj = try JSONSerialization.jsonObject(with: Data(expectedJsonPart.utf8)) as? NSDictionary

        XCTAssertEqual(resultObj, expectedObj)
    }

    func testEmptyArrayAndObjectPointers() {
        let template = "<svg>{{/emptyArray}},{{/emptyObject}}</svg>"
        let json: [String: Any] = ["emptyArray": [], "emptyObject": [:]]
        let expected = "<svg>[],{}</svg>"
        let result = JsonPointerResolver.replacePlaceholders(svgTemplate: template, vcJson : json)
        XCTAssertEqual(result, expected)
    }

    func testArrayIndexOutOfBoundsReturnsDash() {
        let template = "<svg>{{/items/99}}</svg>"
        let json: [String: Any] = ["items": ["one", "two"]]
        let expected = "<svg>-</svg>"
        let result = JsonPointerResolver.replacePlaceholders(svgTemplate: template, vcJson : json)
        XCTAssertEqual(result, expected)
    }

    func testMultipleTildesAndSlashesInKey() {
        let template = "<svg>{{/a~0b~1c}}</svg>"
        let json: [String: Any] = ["a~b/c": "value"]
        let expected = "<svg>value</svg>"
        let result = JsonPointerResolver.replacePlaceholders(svgTemplate: template, vcJson : json)

        XCTAssertEqual(result, expected)
    }

    func testSpecialCharactersInKeys() {
        let template = "<svg>{{/!@#$%^&*()}}</svg>"
        let json: [String: Any] = ["!@#$%^&*()": "special"]
        let expected = "<svg>special</svg>"
        let result = JsonPointerResolver.replacePlaceholders(svgTemplate: template, vcJson : json)

        XCTAssertEqual(result, expected)
    }

    func testUnicodeCharactersInKeys() {
        let template = "<svg>{{/ключ}}</svg>"
        let json: [String: Any] = ["ключ": "значение"]
        let expected = "<svg>значение</svg>"
        let result = JsonPointerResolver.replacePlaceholders(svgTemplate: template, vcJson : json)

        XCTAssertEqual(result, expected)
    }

    func testReplaceSimpleObjectFieldWithRenderProperty() {
        let template = "<svg >{{/issuer}}##{{/credentialSubject/fullName}}</svg>"
        let json: [String: Any] = [
            "issuer": "did:mosip:123456789",
            "credentialSubject": [
                "gender": [["language": "eng", "value": "English Male"]],
                "fullName": "John"
            ]
        ]
        let expected = "<svg >did:mosip:123456789##-</svg>"
        let result = JsonPointerResolver.replacePlaceholders(svgTemplate: template, vcJson : json,  renderProperties: ["/issuer"])
        XCTAssertEqual(result, expected)
    }

    func testReplaceSimpleObjectFieldWithRenderPropertyAsArrayIndex() {
        let template = "<svg >{{/credentialSubject/gender/0/value}}##{{/credentialSubject/fullName}}</svg>"
        let json: [String: Any] = [
            "issuer": "did:mosip:123456789",
            "credentialSubject": [
                "gender": [["language": "eng", "value": "English Male"]],
                "fullName": "John"
            ]
        ]
        let expected = "<svg >English Male##-</svg>"
        let result = JsonPointerResolver.replacePlaceholders(svgTemplate: template, vcJson : json, renderProperties: ["/credentialSubject/gender/0/value"])

       XCTAssertEqual(result, expected)
    }
}
