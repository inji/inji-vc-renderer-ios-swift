import Foundation
import pixelpass

public class QrCodeGenerator: QrCodeGeneratorProtocol {
    
    private let pixelPass = PixelPass()
    
    func generateFromVcJson(vcJson: String, traceabilityId: String) throws -> String {
        if let qrCodeData = pixelPass.generateQRCode(data: vcJson, ecc: .M, header: "HDR") {
            return qrCodeData.base64EncodedString()
        }
        throw QRCodeGenerationFailureException(traceabilityId: traceabilityId, className: "QrCodeGenerator")
    }
    
    func generateFromQrData(qrData: String, traceabilityId: String) throws -> String {
        if let qrCodeData = pixelPass.generateQRImageData(qrText: qrData, ecc: .M) {
            return qrCodeData.base64EncodedString()
        }
        print("QrCodeGenerator Failed to generate QR traceabilityId=\(traceabilityId)")
        throw QRCodeGenerationFailureException(traceabilityId: traceabilityId, className: "QrCodeGenerator")
    }
}

protocol QrCodeGeneratorProtocol {
    func generateFromVcJson(vcJson: String, traceabilityId: String) throws -> String
    func generateFromQrData(qrData: String, traceabilityId: String) throws -> String
}
