import XCTest
import Foundation
import InjiVcRenderer

final class SvgPlaceholderHelperTests: XCTestCase {
    
    func testReplaceFieldsWithLocaleInTemplateAndVC() {
        let svgTemplate = "<svg lang=\"eng\">{{/credentialSubject/gender}}##{{/credentialSubject/fullName}}</svg>"
        
        let vcJson: [String: Any] = [
            "credentialSubject": [
                "gender": [
                    ["language": "eng", "value": "English Male"]
                ],
                "fullName": "John"
            ]
        ]
        
        let expected = "<svg lang=\"eng\">English Male##John</svg>"
        let result = SvgPlaceholderHelper.replacePlaceholders(svgTemplate: svgTemplate, jsonObject: vcJson)
        XCTAssertEqual(result, expected)
    }
    
    func testReplaceFieldsWithLocaleInTemplateAndNotInVC() {
        let svgTemplate = "<svg lang=\"eng\">{{/credentialSubject/gender}}</svg>"
        
        let vcJson: [String: Any] = [
            "credentialSubject": [
                "gender": "Male"
            ]
        ]
        
        let expected = "<svg lang=\"eng\">Male</svg>"
        let result = SvgPlaceholderHelper.replacePlaceholders(svgTemplate: svgTemplate, jsonObject: vcJson)
        XCTAssertEqual(result, expected)
    }
    
    func testReplaceFieldsWithLocaleNotInTemplateButInVC() {
        let svgTemplate = "<svg>{{/credentialSubject/gender}}</svg>"
        
        let vcJson: [String: Any] = [
            "credentialSubject": [
                "gender": [
                    ["language": "eng", "value": "English Male"],
                    ["language": "fr", "value": "French Male"]
                ]
            ]
        ]
        
        let expected = "<svg>English Male</svg>"
        let result = SvgPlaceholderHelper.replacePlaceholders(svgTemplate: svgTemplate, jsonObject: vcJson)
        XCTAssertEqual(result, expected)
    }
    
    func testReplaceFieldsWithLocaleNotInTemplateAndNotInVC() {
        let svgTemplate = "<svg>{{/credentialSubject/gender}}</svg>"
        
        let vcJson: [String: Any] = [
            "credentialSubject": [
                "gender": "Male"
            ]
        ]
        
        let expected = "<svg>Male</svg>"
        let result = SvgPlaceholderHelper.replacePlaceholders(svgTemplate: svgTemplate, jsonObject: vcJson)
        XCTAssertEqual(result, expected)
    }
    
    func testReplaceFieldsLocaleMismatchDefaultToEnglish() {
        let svgTemplate = "<svg lang=\"fr\">{{/credentialSubject/gender}}</svg>"
        
        let vcJson: [String: Any] = [
            "credentialSubject": [
                "gender": [
                    ["language": "tam", "value": "Tamil Male"],
                    ["language": "eng", "value": "English Male"]
                ]
            ]
        ]
        
        let expected = "<svg lang=\"fr\">English Male</svg>"
        let result = SvgPlaceholderHelper.replacePlaceholders(svgTemplate: svgTemplate, jsonObject: vcJson)
        XCTAssertEqual(result, expected)
    }
    
    func testReplaceFieldsLocaleMismatchDefaultToFirst() {
        let svgTemplate = "<svg lang=\"fr\">{{/credentialSubject/gender}}</svg>"
        
        let vcJson: [String: Any] = [
            "credentialSubject": [
                "gender": [
                    ["language": "tam", "value": "Tamil Male"],
                    ["language": "spanish", "value": "Spanish Male"]
                ]
            ]
        ]
        
        let expected = "<svg lang=\"fr\">Tamil Male</svg>"
        let result = SvgPlaceholderHelper.replacePlaceholders(svgTemplate: svgTemplate, jsonObject: vcJson)
        XCTAssertEqual(result, expected)
    }
    
    func testReplaceBenefitsArrayIntoMultiline() {
        let svgTemplate = "<svg width=\"340\" height=\"234\">\n<text>{{/credentialSubject/benefits}}</text></svg>"
        
        let vcJson: [String: Any] = [
            "credentialSubject": [
                "fullName": "John Doe",
                "benefits": [
                    "Item 1 is on the list",
                    "Item 2 is on the list",
                    "Item 3 is on the list",
                    "Item 4 is on the list",
                    "Item 5 is on the list",
                    "Item 6 is on the list"
                ]
            ],
            "renderMethod": [
                "type": "TemplateRenderMethod",
                "renderSuite": "svg-mustache",
                "template": [
                    "id": "https://degree.example/credential-templates/benefits-mutliline.svg",
                    "mediaType": "image/svg+xml",
                    "digestMultibase": "zQmerWC85Wg6wFl9znFCwYxApG270iEu5h6JqWAPdhyxz2dR"
                ]
            ]
        ]
        
        let expected = "<svg width=\"340\" height=\"234\">\n<text><tspan x=\"0\" dy=\"1.2em\">Item 1 is on the list, Item 2 is on the</tspan><tspan x=\"0\" dy=\"1.2em\">list, Item 3 is on the list, Item 4 is on</tspan><tspan x=\"0\" dy=\"1.2em\">the list, Item 5 is on the list, Item 6 is</tspan><tspan x=\"0\" dy=\"1.2em\">on the list</tspan></text></svg>"
        
        let result = SvgPlaceholderHelper.replacePlaceholders(svgTemplate: svgTemplate, jsonObject: vcJson)
        XCTAssertEqual(result, expected)
    }
    
    func testConcatenatedAddressWithLocale() {
        let svgTemplate = "<svg lang=\"eng\">{{/credentialSubject/concatenatedAddress}}</svg>"
        
        let vcJson: [String: Any] = [
            "credentialSubject": [
                "addressLine1": [
                    ["language": "eng", "value": "TEST_ADDRESS_LINE_1eng"],
                    ["language": "fr", "value": "TEST_ADDRESS_LINE_1fr"]
                ],
                "addressLine2": [["language": "eng", "value": "TEST_ADDRESS_LINE_2eng"]],
                "city": [["language": "eng", "value": "TEST_CITYeng"]],
                "province": [["language": "eng", "value": "TEST_PROVINCEeng"]],
                "region": [["language": "eng", "value": "TEST_REGIONeng"]],
                "postalCode": [["language": "eng", "value": "TEST_POSTAL_CODEeng"]]
            ]
        ]
        
        let expected = "<svg lang=\"eng\"><tspan x=\"0\" dy=\"1.2em\"></tspan><tspan x=\"0\" dy=\"1.2em\">TEST_ADDRESS_LINE_1eng,</tspan><tspan x=\"0\" dy=\"1.2em\">TEST_ADDRESS_LINE_2eng,</tspan><tspan x=\"0\" dy=\"1.2em\">TEST_CITYeng,</tspan><tspan x=\"0\" dy=\"1.2em\">TEST_PROVINCEeng,</tspan><tspan x=\"0\" dy=\"1.2em\">TEST_REGIONeng,</tspan><tspan x=\"0\" dy=\"1.2em\">TEST_POSTAL_CODEeng</tspan></svg>"
        
        let result = SvgPlaceholderHelper.replacePlaceholders(svgTemplate: svgTemplate, jsonObject: vcJson)
        XCTAssertEqual(result, expected)
    }
    func testConcatenatedAddressWithoutLocale() {
        let svgTemplate = "<svg>{{/credentialSubject/concatenatedAddress}}</svg>"
        
        let vcJson: [String: Any] = [
            "credentialSubject": [
                "addressLine1": [
                    ["language": "eng", "value": "TEST_ADDRESS_LINE_1eng"],
                    ["language": "fr", "value": "TEST_ADDRESS_LINE_1fr"]
                ],
                "addressLine2": [["language": "eng", "value": "TEST_ADDRESS_LINE_2eng"]],
                "city": [["language": "eng", "value": "TEST_CITYeng"]],
                "province": [["language": "eng", "value": "TEST_PROVINCEeng"]],
                "region": [["language": "eng", "value": "TEST_REGIONeng"]],
                "postalCode": [["language": "eng", "value": "TEST_POSTAL_CODEeng"]]
            ]
        ]
        
        let expected = "<svg><tspan x=\"0\" dy=\"1.2em\"></tspan><tspan x=\"0\" dy=\"1.2em\">TEST_ADDRESS_LINE_1eng,</tspan><tspan x=\"0\" dy=\"1.2em\">TEST_ADDRESS_LINE_2eng,</tspan><tspan x=\"0\" dy=\"1.2em\">TEST_CITYeng,</tspan><tspan x=\"0\" dy=\"1.2em\">TEST_PROVINCEeng,</tspan><tspan x=\"0\" dy=\"1.2em\">TEST_REGIONeng,</tspan><tspan x=\"0\" dy=\"1.2em\">TEST_POSTAL_CODEeng</tspan></svg>"
        
        let result = SvgPlaceholderHelper.replacePlaceholders(svgTemplate: svgTemplate, jsonObject: vcJson)
        XCTAssertEqual(result, expected)
    }
}
