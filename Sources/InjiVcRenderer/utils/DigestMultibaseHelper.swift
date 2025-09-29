import Foundation
import CryptoKit


class DigestMultibaseHelper {
    private let traceabilityId: String
    private let className = String(describing: DigestMultibaseHelper.self)
    
    init(traceabilityId: String) {
        self.traceabilityId = traceabilityId
    }
    
    func validateDigestMultibase(svgString: String, digestMultibase: String) throws -> Bool {
        guard digestMultibase.hasPrefix("u") else {
            throw MultibaseValidationException(traceabilityId: traceabilityId, className: className,  exceptionMessage: "digestMultibase must start with 'u'")
        }
        
        let encodedPart = String(digestMultibase.dropFirst())
        guard let decoded = base64UrlNoPadDecode(encodedPart) else {
            throw MultibaseValidationException(traceabilityId: traceabilityId, className: className,  exceptionMessage: "Base64 Decoding error")
        }
        
        guard decoded.count == 34 else {
            throw MultibaseValidationException(traceabilityId: traceabilityId, className: className,  exceptionMessage: "Invalid multihash length")
        }
        
        guard decoded[0] == 0x12 && decoded[1] == 0x20 else {
            throw MultibaseValidationException(traceabilityId: traceabilityId, className: className,  exceptionMessage: "Unsupported multihash prefix")
        }
        
        let expectedHash = decoded.subdata(in: 2..<34)
        let actualHash = Data(SHA256.hash(data: Data(svgString.utf8)))
        
        return expectedHash == actualHash
    }
    
    private func base64UrlNoPadDecode(_ string: String) -> Data? {
        var base64 = string
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        
        let padding = 4 - (base64.count % 4)
        if padding < 4 {
            base64.append(String(repeating: "=", count: padding))
        }
        
        return Data(base64Encoded: base64)
    }
}
