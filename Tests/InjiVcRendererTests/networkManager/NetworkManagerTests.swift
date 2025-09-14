import XCTest
@testable import InjiVcRenderer

// Custom URLProtocol to stub responses
class MockURLProtocol: URLProtocol {
    static var responseData: Data?
    static var response: URLResponse?
    static var error: Error?

    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        if let error = MockURLProtocol.error {
            self.client?.urlProtocol(self, didFailWithError: error)
        } else {
            if let response = MockURLProtocol.response {
                self.client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }
            if let data = MockURLProtocol.responseData {
                self.client?.urlProtocol(self, didLoad: data)
            }
            self.client?.urlProtocolDidFinishLoading(self)
        }
    }

    override func stopLoading() {}
}

final class NetworkManagerTests: XCTestCase {
    var networkManager: NetworkManager!

    override func setUp() {
        super.setUp()
        networkManager = NetworkManager()

        let config = URLSessionConfiguration.default
        config.protocolClasses = [MockURLProtocol.self]
        URLSession.shared.configuration.protocolClasses = config.protocolClasses
        
        URLProtocol.registerClass(MockURLProtocol.self)

    }

    override func tearDown() {
        networkManager = nil
        MockURLProtocol.responseData = nil
        MockURLProtocol.response = nil
        MockURLProtocol.error = nil
        
        URLProtocol.unregisterClass(MockURLProtocol.self)

        super.tearDown()
    }

    func testFetchSvg_InvalidUrl() {
        XCTAssertThrowsError(
            try networkManager.fetchSvgAsText(url: "not a url", traceabilityId: "trace-1")
        ) { error in
            XCTAssertTrue(error is VcRendererException)
            XCTAssertEqual((error as? VcRendererException)?.errorCode, VcRendererErrorCodes.svgFetchError)
        }
    }


    func testFetchSvg_NetworkError() {
        MockURLProtocol.error = NSError(domain: "TestError", code: -1009)

        XCTAssertThrowsError(
            try networkManager.fetchSvgAsText(url: "https://example.com/file.svg", traceabilityId: "trace-2")
        ) { error in
            XCTAssertTrue(error is VcRendererException)
            XCTAssertEqual((error as? VcRendererException)?.errorCode, VcRendererErrorCodes.svgFetchError)
        }
    }

    func testFetchSvg_InvalidResponse() {
        MockURLProtocol.response = URLResponse(url: URL(string: "https://example.com")!,
                                               mimeType: nil,
                                               expectedContentLength: 0,
                                               textEncodingName: nil)

        XCTAssertThrowsError(
            try networkManager.fetchSvgAsText(url: "https://example.com/file.svg", traceabilityId: "trace-3")
        )
    }

    
    func testFetchSvg_UnexpectedStatusCode_shouldThrowException() {
        let response = HTTPURLResponse(
            url: URL(string: "https://example.com")!,
            statusCode: 404,
            httpVersion: nil,
            headerFields: ["Content-Type": "image/svg+xml"]
        )!
        MockURLProtocol.response = response
        MockURLProtocol.responseData = "Not found".data(using: .utf8)

        XCTAssertThrowsError(
            try networkManager.fetchSvgAsText(
                url: "https://example.com/file.svg",
                traceabilityId: "trace-404"
            )
        ) { error in
            guard let vcError = error as? VcRendererException else {
                XCTFail("Expected VcRendererException, got \(error)")
                return
            }
            XCTAssertEqual(vcError.errorCode, VcRendererErrorCodes.svgFetchError)
            XCTAssertTrue(vcError.message.contains("Unexpected response code: 404"))
        }
    }


    func testFetchSvg_InvalidMimeType() {
        let response = HTTPURLResponse(url: URL(string: "https://example.com")!,
                                       statusCode: 200,
                                       httpVersion: nil,
                                       headerFields: ["Content-Type": "text/plain"])!
        MockURLProtocol.response = response
        MockURLProtocol.responseData = "<svg></svg>".data(using: .utf8)

        XCTAssertThrowsError(
            try networkManager.fetchSvgAsText(url: "https://example.com/file.svg", traceabilityId: "trace-5")
        )
    }

    func testFetchSvg_Success() throws {
        let response = HTTPURLResponse(
            url: URL(string: "https://example.com")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: ["Content-Type": "image/svg+xml"]
        )!
        MockURLProtocol.response = response
        MockURLProtocol.responseData = "<svg>ok</svg>".data(using: .utf8)

        let result = try networkManager.fetchSvgAsText(
            url: "https://example.com/file.svg",
            traceabilityId: "trace-6"
        )

        XCTAssertEqual(result, "<svg>ok</svg>")
    }

}
