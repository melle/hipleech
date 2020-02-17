import XCTest
@testable import HipLeech

final class HipLeechTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(HipLeech().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
