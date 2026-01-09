import Foundation
import pixelpass

public class QrCodeGenerator: QrCodeGeneratorProtocol {

    
    func generateQRCodeImage(qrData: String, traceabilityId: String) throws -> String {
        let pixelPass = PixelPass()
        if let qrCodeData = pixelPass.generateQRCode(data: qrData, ecc: .M, header: "HDR") {
            return qrCodeData.base64EncodedString()
        }
        throw QRCodeGenerationFailureException(traceabilityId: traceabilityId, className: "QrCodeGenerator")
    }
    
    public func generateQRCodeImage(
            vcJson: String,
            traceabilityId: String
        ) throws -> String {
            return try generateQRCodeImage(
                qrData: vcJson,
                traceabilityId: traceabilityId
            )
        }
}

protocol QrCodeGeneratorProtocol {
    func generateQRCodeImage(vcJson: String, traceabilityId: String) throws -> String
}
