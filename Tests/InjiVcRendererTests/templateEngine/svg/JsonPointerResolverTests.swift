import XCTest

@testable import InjiVcRenderer

final class JsonPointerResolverTests: XCTestCase {
    
    let traceabilityId = "test-id"


    func testReplaceSimpleObjectField() throws {
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
        let result =  try JsonPointerResolver.replacePlaceholders(svgTemplate: template, inputJson : json, traceabilityId: traceabilityId)
        XCTAssertEqual(result, expected)
    }

    func testReplaceArrayFields() throws {
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
        let result = try JsonPointerResolver.replacePlaceholders(svgTemplate: template, inputJson : json, traceabilityId: traceabilityId)
        XCTAssertEqual(result, expected)
    }

    func testReplaceMissingPointerReturnsDash() throws {
        let template = "<svg >{{/credentialSubject/email}}##{{/credentialSubject/middleName}}</svg>"
        let json: [String: Any] = [
            "credentialSubject": [
                "gender": [["language": "eng", "value": "English Male"]],
                "fullName": "John"
            ]
        ]
        let expected = "<svg >-##-</svg>"
        let result = try JsonPointerResolver.replacePlaceholders(svgTemplate: template, inputJson : json, traceabilityId: traceabilityId)
        XCTAssertEqual(result, expected)
    }

    func testReplaceFieldsWithLocaleAsObjects() throws {
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
        let result = try JsonPointerResolver.replacePlaceholders(svgTemplate: template, inputJson : json, traceabilityId: traceabilityId)
        XCTAssertEqual(result, expected)
    }

    func testReplaceFieldsWithLocaleAsArrayOfObjects() throws {
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
        let result = try JsonPointerResolver.replacePlaceholders(svgTemplate: template, inputJson : json, traceabilityId: traceabilityId)
        XCTAssertEqual(result, expected)
    }

    func testReplaceNestedAddressFields() throws {
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
        let result = try JsonPointerResolver.replacePlaceholders(svgTemplate: template, inputJson : json, traceabilityId: traceabilityId)
        XCTAssertEqual(result, expected)
    }

    func testReplaceFieldWithSlash() throws {
        let template = "<svg >{{/credentialSubject/ac~1dc}}</svg>"
        let json: [String: Any] = [
            "credentialSubject": ["ac/dc": "current unit"]
        ]
        let expected = "<svg >current unit</svg>"
        let result = try JsonPointerResolver.replacePlaceholders(svgTemplate: template, inputJson : json, traceabilityId: traceabilityId)
        XCTAssertEqual(result, expected)
    }

    func testReplaceFieldWithTilde() throws {
        let template = "<svg >{{/credentialSubject/a~0b}}</svg>"
        let json: [String: Any] = [
            "credentialSubject": ["a~b": "test"]
        ]
        let expected = "<svg >test</svg>"
        let result = try JsonPointerResolver.replacePlaceholders(svgTemplate: template, inputJson : json, traceabilityId: traceabilityId)
        XCTAssertEqual(result, expected)
    }

    func testPointerToRootReturnsFullDocument() throws {
        let template = "<svg>{{}}</svg>"
        let json: [String: Any] = ["a": 1, "b": 2]
        let expected = "<svg>{\"a\":1,\"b\":2}</svg>"
        
        let result = try JsonPointerResolver.replacePlaceholders(svgTemplate: template, inputJson: json, traceabilityId: traceabilityId)
        
        // Extract JSON portion between <svg> tags
        let resultJsonPart = result.replacingOccurrences(of: "<svg>", with: "")
                                    .replacingOccurrences(of: "</svg>", with: "")
        let expectedJsonPart = expected.replacingOccurrences(of: "<svg>", with: "")
                                       .replacingOccurrences(of: "</svg>", with: "")

        let resultObj = try JSONSerialization.jsonObject(with: Data(resultJsonPart.utf8)) as? NSDictionary
        let expectedObj = try JSONSerialization.jsonObject(with: Data(expectedJsonPart.utf8)) as? NSDictionary

        XCTAssertEqual(resultObj, expectedObj)
    }

    func testEmptyArrayAndObjectPointers() throws {
        let template = "<svg>{{/emptyArray}},{{/emptyObject}}</svg>"
        let json: [String: Any] = ["emptyArray": [], "emptyObject": [:]]
        let expected = "<svg>[],{}</svg>"
        let result = try JsonPointerResolver.replacePlaceholders(svgTemplate: template, inputJson : json, traceabilityId: traceabilityId)
        XCTAssertEqual(result, expected)
    }

    func testArrayIndexOutOfBoundsReturnsDash() throws {
        let template = "<svg>{{/items/99}}</svg>"
        let json: [String: Any] = ["items": ["one", "two"]]
        let expected = "<svg>-</svg>"
        let result = try JsonPointerResolver.replacePlaceholders(svgTemplate: template, inputJson : json, traceabilityId: traceabilityId)
        XCTAssertEqual(result, expected)
    }

    func testMultipleTildesAndSlashesInKey() throws {
        let template = "<svg>{{/a~0b~1c}}</svg>"
        let json: [String: Any] = ["a~b/c": "value"]
        let expected = "<svg>value</svg>"
        let result = try JsonPointerResolver.replacePlaceholders(svgTemplate: template, inputJson : json, traceabilityId: traceabilityId)

        XCTAssertEqual(result, expected)
    }

    func testSpecialCharactersInKeys() throws {
        let template = "<svg>{{/!@#$%^&*() throws}}</svg>"
        let json: [String: Any] = ["!@#$%^&*() throws": "special"]
        let expected = "<svg>special</svg>"
        let result = try JsonPointerResolver.replacePlaceholders(svgTemplate: template, inputJson : json, traceabilityId: traceabilityId)

        XCTAssertEqual(result, expected)
    }

    func testUnicodeCharactersInKeys() throws {
        let template = "<svg>{{/ключ}}</svg>"
        let json: [String: Any] = ["ключ": "значение"]
        let expected = "<svg>значение</svg>"
        let result = try JsonPointerResolver.replacePlaceholders(svgTemplate: template, inputJson : json, traceabilityId: traceabilityId)

        XCTAssertEqual(result, expected)
    }

    func testReplaceSimpleObjectFieldWithRenderProperty() throws {
        let template = "<svg >{{/issuer}}##{{/credentialSubject/fullName}}</svg>"
        let json: [String: Any] = [
            "issuer": "did:mosip:123456789",
            "credentialSubject": [
                "gender": [["language": "eng", "value": "English Male"]],
                "fullName": "John"
            ]
        ]
        let expected = "<svg >did:mosip:123456789##-</svg>"
        let result = try JsonPointerResolver.replacePlaceholders(svgTemplate: template, inputJson : json,  renderProperties: ["/issuer"], traceabilityId: traceabilityId)
        XCTAssertEqual(result, expected)
    }

    func testReplaceSimpleObjectFieldWithRenderPropertyAsArrayIndex() throws {
        let template = "<svg >{{/credentialSubject/gender/0/value}}##{{/credentialSubject/fullName}}</svg>"
        let json: [String: Any] = [
            "issuer": "did:mosip:123456789",
            "credentialSubject": [
                "gender": [["language": "eng", "value": "English Male"]],
                "fullName": "John"
            ]
        ]
        let expected = "<svg >English Male##-</svg>"
        let result = try JsonPointerResolver.replacePlaceholders(svgTemplate: template, inputJson : json, renderProperties: ["/credentialSubject/gender/0/value"], traceabilityId: traceabilityId)

       XCTAssertEqual(result, expected)
    }

    

}
