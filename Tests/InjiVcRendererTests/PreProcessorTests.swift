//import XCTest
//import Foundation
//import InjiVcRenderer
//
//class PreProcessorTests: XCTestCase {
//    
//    let templatePreProcessor = PreProcessor()
//    func testLocaleBasedFields() {
//        let vcJsonString = """
//        {
//            "credentialSubject": {
//                "gender": [
//                    {
//                        "language": "eng",
//                        "value": "English Male"
//                    },
//                    {
//                        "language": "tam",
//                        "value": "Tamil Male"
//                    }
//                ]
//            }
//        }
//        """
//        let svgTemplate = "{{credentialSubject/gender/eng}}"
//
//        let expected: [String: Any] = [
//              "credentialSubject": [
//                "gender": ["eng": "English Male", "tam": "Tamil Male"]
//              ]
//          ]
//
//        let result = templatePreProcessor.preProcessVcJson(vcJsonString: vcJsonString, svgTemplate: svgTemplate)
//
//        XCTAssertEqual(result as NSDictionary, expected as NSDictionary, "Locale based Json did not match the expected result")
//    }
//    
//    func testAddressFields() {
//        let vcJsonString = """
//        {
//                    "credentialSubject": {
//                        "addressLine1": [
//                            {
//                                "language": "eng",
//                                "value": "Address Line 1"
//                            },
//                            {
//                                "language": "fr",
//                                "value": "Address Line1 French"
//                            }
//                        ],
//                        "city": [
//                            {
//                                "language": "eng",
//                                "value": "City"
//                            },
//                            {
//                                "language": "fr",
//                                "value": "City French"
//                            }
//                        ]
//                    }
//                }
//        """
//        let svgTemplate = "{{credentialSubject/fullAddressLine1/eng}}"
//
//        let expected: [String: Any] = [
//              "credentialSubject": [
//                "fullAddressLine1": ["eng": "Address Line 1, City"]
//              ]
//          ]
//
//        let result = templatePreProcessor.preProcessVcJson(vcJsonString: vcJsonString, svgTemplate: svgTemplate)
//
//        XCTAssertEqual(result as NSDictionary, expected as NSDictionary, "Address Json did not match the expected result")
//    }
//    
//    func testBenefitsFields() {
//        let vcJsonString = """
//        {
//                    "credentialSubject": {
//                        "benefits": [ "Benefits one, Benefits two"
//                        ]
//                    }
//                }
//        """
//        let svgTemplate = "{{credentialSubject/benefitsLine1}}"
//
//        let expected: [String: Any] = [
//              "credentialSubject": [
//                "benefitsLine1": "Benefits one, Benefits two"
//              ]
//          ]
//
//        let result = templatePreProcessor.preProcessVcJson(vcJsonString: vcJsonString, svgTemplate: svgTemplate)
//
//        XCTAssertEqual(result as NSDictionary, expected as NSDictionary, "Benefits Json did not match the expected result")
//    }
//    
//    
//
//}
//
//enum JSONError: Error {
//    case invalidData
//    case parsingError
//}
