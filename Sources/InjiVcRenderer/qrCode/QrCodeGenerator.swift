import Foundation
import pixelpass

public class QrCodeGenerator: QrCodeGeneratorProtocol {

    
    func generateQRCodeVcJson(vcJson: String, traceabilityId: String) throws -> String {
        let pixelPass = PixelPass()
        if let qrCodeData = pixelPass.generateQRCode(data: vcJson, ecc: .M, header: "HDR") {
            return qrCodeData.base64EncodedString()
        }
        throw QRCodeGenerationFailureException(traceabilityId: traceabilityId, className: "QrCodeGenerator")
    }
    
    func generateQRCodeQrData(qrData: String, traceabilityId: String) throws -> String {
        let pixelPass = PixelPass()
        if let qrCodeData = pixelPass.generateQRImageData(data: qrData, ecc: .M) {
            return qrCodeData.base64EncodedString()
        }
        throw QRCodeGenerationFailureException(traceabilityId: traceabilityId, className: "QrCodeGenerator")
    }
}

protocol QrCodeGeneratorProtocol {
    func generateQRCodeVcJson(vcJson: String, traceabilityId: String) throws -> String
    func generateQRCodeQrData(qrData: String, traceabilityId: String) throws -> String
}
