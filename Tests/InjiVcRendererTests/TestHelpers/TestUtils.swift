

@testable import InjiVcRenderer
import Foundation
import XCTest
import CryptoKit

class TestUtils {
    private static func base64UrlNoPadEncode(_ data: Data) -> String {
         let encoded = data.base64EncodedString()
         return encoded
             .replacingOccurrences(of: "+", with: "-")
             .replacingOccurrences(of: "/", with: "_")
             .replacingOccurrences(of: "=", with: "")
     }
    
     static func generateDigestMultibase(svgString: String) throws -> String {
         let svgBytes = Data(svgString.utf8)
         
         let hash = SHA256.hash(data: svgBytes)
         var multihash = Data([0x12, 0x20])
         multihash.append(contentsOf: hash)
         let encoded = base64UrlNoPadEncode(multihash)
         return "u" + encoded
     }
    
    
}




