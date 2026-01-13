import XCTest
@testable import InjiVcRenderer
@testable import pixelpass


class MockPixelPass: PixelPass {
    var shouldReturnData: Bool = true
    
    override func generateQRCode(data: String, ecc: ECC, header: String) -> Data? {
        return shouldReturnData ? "mock-data".data(using: .utf8) : nil
    }
}

final class QrCodeGeneratorTests: XCTestCase {

    func testGenerateQRCodeImage_success() throws {
        let mockPixelPass = MockPixelPass()
        mockPixelPass.shouldReturnData = true
        let generator = QrCodeGenerator()
        
    
        let mirror = Mirror(reflecting: generator)
        if let pixelPassProp = mirror.children.first(where: { $0.label == "pixelPass" })?.value as? PixelPass {
            _ = pixelPassProp
        }
        
        let result = try generator.generateQRCodeVcJson(vcJson: "{\"id\":\"123\"}", traceabilityId: "trace-1")
        
        XCTAssertFalse(result.isEmpty)
        XCTAssertNotNil(Data(base64Encoded: result))
    }
    
    func testGenerateQRCodeImage_failure() {
        let mockPixelPass = MockPixelPass()
        mockPixelPass.shouldReturnData = false
        let generator = QrCodeGenerator()
        
        XCTAssertThrowsError(try generator.generateQRCodeVcJson(vcJson: "", traceabilityId: "trace-2")) { error in
            XCTAssertTrue(error is QRCodeGenerationFailureException)
        }
    }
    
    func testGenerateQRCodeQrData_success() throws {
        let generator = QrCodeGenerator()
        // Use a simple, valid input that PixelPass can handle
        let result = try generator.generateQRCodeQrData(qrData: "HELLO-QR-DATA", traceabilityId: "trace-qr-success")
        
        XCTAssertFalse(result.isEmpty, "Base64 PNG data string should not be empty")
        XCTAssertNotNil(Data(base64Encoded: result), "Result should be valid Base64")
    }
    
    func testGenerateQRCodeQrData_failureOnEmptyInput() {
        let generator = QrCodeGenerator()
        
        XCTAssertThrowsError(
            try generator.generateQRCodeQrData(qrData: "", traceabilityId: "trace-qr-failure")
        ) { error in
            XCTAssertTrue(error is QRCodeGenerationFailureException)
        }
    }
}

