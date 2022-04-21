import XCTest
import Projection

final class EventDetailsTests: XCTestCase {
    func testDecodesJSON() throws {
        let event = Event(entityId: "", name: "", entityType: "", details: "{}", position: 0)

        XCTAssertNotNil(try event.details(as: TestDetails.self))
    }
}

class TestDetails: Decodable {

}
