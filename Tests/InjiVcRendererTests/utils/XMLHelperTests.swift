import XCTest
@testable import InjiVcRenderer

final class XMLHelperTests: XCTestCase {
    private let traceabilityId = "test-trace-id"
    private var helper: XMLHelper!

    override func setUp() {
        super.setUp()
        helper = XMLHelper(traceabilityId: traceabilityId)
    }

    func testGetSVGListFromPageSet_success() throws {
        let xml = """
        <pageSet>
            <page>
                <svg><rect width="100" height="100"/></svg>
            </page>
            <page>
                <svg><circle r="50"/></svg>
            </page>
        </pageSet>
        """

        let result = try helper.getSVGListFromPageSet(xml: xml)
        XCTAssertEqual(result.count, 2)
        XCTAssertTrue(result[0].contains("<rect"))
        XCTAssertTrue(result[1].contains("<circle"))
    }

    func testGetSVGListFromPageSet_invalidRoot() {
        let xml = """
        <invalidRoot>
            <page><svg><rect/></svg></page>
        </invalidRoot>
        """

        XCTAssertThrowsError(try helper.getSVGListFromPageSet(xml: xml)) { error in
            guard let vcError = error as? PageSetParsingException else {
                XCTFail("Expected PageSetParsingException, got \(error)")
                return
            }
            XCTAssertEqual(vcError.errorCode, VcRendererErrorCodes.xmlParsingFailed)
            XCTAssertTrue(vcError.message.contains("Root element must be <PageSet>"))
            
        }
    }

    func testGetSVGListFromPageSet_missingPages() {
        let xml = """
        <pageSet>
        </pageSet>
        """

        XCTAssertThrowsError(try helper.getSVGListFromPageSet(xml: xml)) { error in
            guard let vcError = error as? PageSetParsingException else {
                XCTFail("Expected PageSetParsingException, got \(error)")
                return
            }
            XCTAssertEqual(vcError.errorCode, VcRendererErrorCodes.xmlParsingFailed)
            XCTAssertTrue(vcError.message.contains("<pageSet> must contain at least one <page> element"))
            
        }
    }

    func testGetSVGListFromPageSet_invalidXML() {
        let xml = """
        <pageSet>
            <page>
                <svg><rect></svg> <!-- malformed -->
            </page>
        </pageSet>
        """

        XCTAssertThrowsError(try helper.getSVGListFromPageSet(xml: xml)) { error in
            
            guard let vcError = error as? PageSetParsingException else {
                XCTFail("Expected PageSetParsingException, got \(error)")
                return
            }
            XCTAssertEqual(vcError.errorCode, VcRendererErrorCodes.xmlParsingFailed)
            XCTAssertTrue(vcError.message.contains("The operation couldn’t be completed"))
            
        }
    }
}
