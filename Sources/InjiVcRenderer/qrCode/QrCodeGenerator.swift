import Foundation
import pixelpass

public class QrCodeGenerator: QrCodeGeneratorProtocol {

    
    func generateFromVcJson(vcJson: String, traceabilityId: String) throws -> String {
        let pixelPass = PixelPass()
        if let qrCodeData = pixelPass.generateQRCode(data: vcJson, ecc: .M, header: "HDR") {
            return qrCodeData.base64EncodedString()
        }
        throw QRCodeGenerationFailureException(traceabilityId: traceabilityId, className: "QrCodeGenerator")
    }
    
    func generateFromQrData(qrData: String, traceabilityId: String) throws -> String {
        let pixelPass = PixelPass()
        if let qrCodeData = pixelPass.generateQRImageData(data: qrData, ecc: .M) {
            return qrCodeData.base64EncodedString()
        }
        throw QRCodeGenerationFailureException(traceabilityId: traceabilityId, className: "QrCodeGenerator")
    }
}

protocol QrCodeGeneratorProtocol {
    func generateFromVcJson(vcJson: String, traceabilityId: String) throws -> String
    func generateFromQrData(qrData: String, traceabilityId: String) throws -> String
}
