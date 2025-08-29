//import Foundation
//import pixelpass
//
//public class QrCodeGenerator {
//    
//    private let BASE64_PNG_IMAGE_PREFIX = "data:image/png;base64,"
//    
//    func generateQRCodeImage(vcJson: String) -> String {
//        do {
//            let pixelPass = PixelPass()
//            let qrData = try pixelPass.generateQRData(vcJson: vcJson)
//            
//            if qrData.count <= 10000 {
//                if let base64String = convertQrDataIntoBase64(qrData: qrData) {
//                    return BASE64_PNG_IMAGE_PREFIX + base64String
//                }
//            }
//            return ""
//        } catch {
//            print("Error generating QR Code: \(error)")
//            return ""
//        }
//    }
//    
//    private func convertQrDataIntoBase64(qrData: String) -> String? {
//        guard let data = qrData.data(using: .utf8) else {
//            return nil
//        }
//        
//        // Generate QR code image from string
//        if let filter = CIFilter(name: "CIQRCodeGenerator") {
//            filter.setValue(data, forKey: "inputMessage")
//            filter.setValue("M", forKey: "inputCorrectionLevel")
//            
//            if let qrImage = filter.outputImage {
//                // Scale image up
//                let transformedImage = qrImage.transformed(by: CGAffineTransform(scaleX: 10, y: 10))
//                
//                let context = CIContext()
//                if let cgImage = context.createCGImage(transformedImage, from: transformedImage.extent) {
//                    let uiImage = UIImage(cgImage: cgImage)
//                    if let pngData = uiImage.pngData() {
//                        return pngData.base64EncodedString()
//                    }
//                }
//            }
//        }
//        
//        return nil
//    }
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
