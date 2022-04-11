import XCTest
import EventStore

final class ReconstitutionTests: XCTestCase {
    func test_() throws {
        let history = History(events: [PublishedEvent(name: "test")])

        let entity: TestEntity = history.reconstitute()

        XCTAssertNotNil(entity)
        XCTAssertEqual(entity.lastReconstitutedEvent?.name, "test")
    }
}

final class TestEntity: Entity {
    var lastReconstitutedEvent: PublishedEvent?

    func apply(_ event: PublishedEvent) {
        lastReconstitutedEvent = event
    }
}
