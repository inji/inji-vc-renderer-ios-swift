//import Foundation
//import pixelpass
//
//public class PreProcessor {
//    
//    public init() {}
//    
//    private let QRCODE_IMAGE_TYPE = "data:image/png;base64,"
//
//    public func preProcessVcJson(vcJsonString: String, svgTemplate: String) -> [String: Any] {
//        
//        guard let data = vcJsonString.data(using: .utf8),
//              var vcJsonObject = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
//              var credentialSubject = vcJsonObject["credentialSubject"] as? [String: Any] else {
//            return [:]
//        }
//
//        credentialSubject = replaceFieldsWithLanguage(credentialSubject)
//        
//        credentialSubject = MultiLineHandler().handleMultiLineFields(credentialSubject: credentialSubject, svgTemplate : svgTemplate)
//
//        // Check for {{qrCodeImage}} for QR Code Replacement
//        if svgTemplate.contains(PreProcessor.QR_CODE_PLACEHOLDER) {
//            let qrCodeImage = replaceQRCode(vcJsonString)
//            credentialSubject[Utils.getFieldNameFromPlaceholder(PreProcessor.QR_CODE_PLACEHOLDER)] = qrCodeImage
//        }
//        
//        vcJsonObject["credentialSubject"] = credentialSubject
//        return vcJsonObject
//    }
//
//    private func replaceFieldsWithLanguage(_ jsonObject: [String: Any]) -> [String: Any] {
//        var updatedJsonObject = jsonObject
//
//        for (key, value) in jsonObject {
//            if let arrayValue = value as? [[String: Any]] {
//                var languageMap = [String: String]()
//                for item in arrayValue {
//                    if let language = item["language"] as? String, let newValue = item["value"] as? String {
//                        languageMap[language] = newValue
//                    }
//                }
//                if !languageMap.isEmpty {
//                    updatedJsonObject[key] = languageMap
//                }
//            } else if let nestedObject = value as? [String: Any] {
//                updatedJsonObject[key] = replaceFieldsWithLanguage(nestedObject)
//            }
//        }
//
//        return updatedJsonObject
//    }
//
//
//
//
//
//    private func replaceQRCode(_ vcJson: String) -> String? {
//        let pixelPass = PixelPass()
//        if let qrCodeData = pixelPass.generateQRCode(data: vcJson,  ecc: .M, header: "HDR") {
//            let base64String = QRCODE_IMAGE_TYPE + qrCodeData.base64EncodedString()
//            return base64String
//        }
//        return nil
//    }
//}
//
//extension PreProcessor {
//    static let CREDENTIAL_SUBJECT_FIELD = "credentialSubject"
//    static let QR_CODE_PLACEHOLDER = "{{credentialSubject/qrCodeImage}}"
//}
