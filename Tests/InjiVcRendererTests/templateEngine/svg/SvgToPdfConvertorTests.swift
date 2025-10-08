import XCTest
@testable import InjiVcRenderer

final class SvgToPdfConvertorTests: XCTestCase {

    func testSvgListToPdfBase64_withValidSvg_returnsNonEmptyBase64() async {
        // Minimal valid SVG content
        let simpleSvg = """
        <svg xmlns="http://www.w3.org/2000/svg" width="100" height="100">
          <circle cx="50" cy="50" r="40" stroke="green" stroke-width="4" fill="yellow" />
        </svg>
        """

        // Call the async method
        let base64Pdf = await SvgToPdfConvertor.svgListToPdfBase64(svgList: [simpleSvg])

        // Assert result is not nil and has some content
        XCTAssertNotNil(base64Pdf, "PDF Base64 should not be nil")
        XCTAssertFalse(base64Pdf!.isEmpty, "PDF Base64 should not be empty")

        // Optional: decode base64 and verify PDF header bytes (starts with %PDF-)
        if let data = Data(base64Encoded: base64Pdf!) {
            let pdfHeader = String(data: data.prefix(5), encoding: .ascii)
            XCTAssertEqual(pdfHeader, "%PDF-", "Generated data should start with PDF header")
        } else {
            XCTFail("Failed to decode base64 PDF data")
        }
    }

    func testSvgListToPdfBase64_withEmptyList_returnsNil() async {
        let base64Pdf = await SvgToPdfConvertor.svgListToPdfBase64(svgList: [])
        XCTAssertNil(base64Pdf, "PDF Base64 should be nil when SVG list is empty")
    }
}
