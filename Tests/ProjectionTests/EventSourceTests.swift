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

    private func event(named name: String) -> Event {
        Event(
            entityId: "some_entity",
            name: name,
            entityType: "some_type",
            details: "{}",
            position: 0)
    }
}

struct MockDatabase: Database {
    var nextEvent: Event?
}

final class TestReceptacle: Receptacle {
    init(handledEvents: [String]) {}
}
