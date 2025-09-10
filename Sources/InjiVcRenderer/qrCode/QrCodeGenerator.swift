import Foundation
import pixelpass

public class QrCodeGenerator: QrCodeGeneratorProtocol {

    
    func generateQRCodeImage(vcJson: String, traceabilityId: String) throws -> String {
        let pixelPass = PixelPass()
        if let qrCodeData = pixelPass.generateQRCode(data: vcJson, ecc: .M, header: "HDR") {
            return qrCodeData.base64EncodedString()
        }
        throw QRCodeGenerationFailureException(traceabilityId: traceabilityId, className: "QrCodeGenerator")
    }
}

protocol QrCodeGeneratorProtocol {
    func generateQRCodeImage(vcJson: String, traceabilityId: String) throws -> String
}
