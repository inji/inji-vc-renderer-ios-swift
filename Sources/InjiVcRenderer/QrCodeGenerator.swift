import Foundation
import pixelpass

public class QrCodeGenerator {
    
    func generateQRCodeImage(vcJson: String) -> String {
        let pixelPass = PixelPass()
        if let qrCodeData = pixelPass.generateQRCode(data: vcJson, ecc: .M, header: "HDR") {
            let base64String = qrCodeData.base64EncodedString()
            return base64String
        }
        return ""
    }
}
