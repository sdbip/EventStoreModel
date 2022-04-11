import XCTest
@testable import EventStore

final class EventStoreTests: XCTestCase {
    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(EventStore().text, "Hello, World!")
    }
}
