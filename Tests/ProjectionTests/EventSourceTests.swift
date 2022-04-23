import XCTest
import Projection

final class EventSourceTests: XCTestCase {
    var eventSource: EventSource!
    var database: MockDatabase!

    override func setUp() {
        database = MockDatabase()
        eventSource = EventSource(database: database)
    }

    func testSwallowsEventIfNoReceiver() throws {
        eventSource.add(TestReceptacle(handledEvents: ["NotSentEvent"]))
        database.nextEvent = event(named: "UnhandledEvent")

        try eventSource.projectEvents(count: 1)
    }

    func testForwardsEventToReceiver() throws {
        let receptacle = TestReceptacle(handledEvents: ["TheEvent"])
        eventSource.add(receptacle)
        database.nextEvent = event(named: "TheEvent")

        try eventSource.projectEvents(count: 1)

        XCTAssertEqual(receptacle.receivedEvent, "TheEvent")
    }

    private func event(named name: String) -> Event {
        Event(
            entityId: "some_entity",
            name: name,
            entityType: "some_type",
            details: "{}",
            position: 0)
    }
}

final class MockDatabase: Database {
    var nextEvent: Event?
}

final class TestReceptacle: Receptacle {
    var receivedEvent: String?

    init(handledEvents: [String]) {}

    func receive(_ event: Event) {
        receivedEvent = event.name
    }
}
