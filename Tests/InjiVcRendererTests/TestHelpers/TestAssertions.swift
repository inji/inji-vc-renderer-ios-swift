
@testable import InjiVcRenderer
import Foundation
import XCTest



func assertAsyncThrowsError<T>(
    _ expression: @autoclosure () async throws -> T,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #filePath,
    line: UInt = #line,
    _ errorHandler: (_ error: any Error) -> Void = { _ in }
) async {
    do {
        _ = try await expression()
        XCTFail("Expected error to be thrown, but no error was thrown. \(message())", file: file, line: line)
    } catch {
        errorHandler(error)
    }
}

func assertAsyncNoThrowsError<T>(
    _ expression: @autoclosure () async throws -> T,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #filePath,
    line: UInt = #line
) async {
    do {
        _ = try await expression()
    } catch {
        XCTFail("Expected no error to be thrown, but an error was thrown: \(error). \(message())", file: file, line: line)
    }
}

func assertVcRendererException(
    _ error: Error,
    expectedMessage: String,
    expectedCode: String,
    file: StaticString = #file,
    line: UInt = #line
) {
    guard let ex = error as? VcRendererException else {
        XCTFail("Expected VcRendererException but got \(error)", file: file, line: line)
        return
    }
    XCTAssertEqual(expectedMessage, ex.message, file: file, line: line)
    XCTAssertEqual(expectedCode, ex.errorCode, file: file, line: line)
}


