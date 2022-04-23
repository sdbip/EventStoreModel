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
        database.nextEvents = [event(named: "UnhandledEvent")]

        try eventSource.projectEvents(count: 1)
    }

    func testForwardsEventToReceiver() throws {
        let receptacle = TestReceptacle(handledEvents: ["TheEvent"])
        eventSource.add(receptacle)
        database.nextEvents = [event(named: "TheEvent")]

        try eventSource.projectEvents(count: 1)

        XCTAssertEqual(receptacle.receivedEvents, ["TheEvent"])
    }

    func testForwardsMultipleEvents() throws {
        let receptacle = TestReceptacle(handledEvents: ["TheEvent"])
        eventSource.add(receptacle)
        database.nextEvents = [event(named: "TheEvent"), event(named: "TheEvent")]

        try eventSource.projectEvents(count: 2)

        XCTAssertEqual(receptacle.receivedEvents, ["TheEvent", "TheEvent"])
    }

    func testForwardsOnlyAsManyEventsAsIndicated() throws {
        let receptacle = TestReceptacle(handledEvents: ["TheEvent"])
        eventSource.add(receptacle)
        database.nextEvents = [event(named: "TheEvent"), event(named: "TheEvent")]

        try eventSource.projectEvents(count: 1)

        XCTAssertEqual(receptacle.receivedEvents, ["TheEvent"])
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
    var nextEvents: [Event] = []

    func readEvents(count: Int) -> [Event] {
        return Array(nextEvents.prefix(count))
    }
}

final class TestReceptacle: Receptacle {
    var receivedEvents: [String] = []

    init(handledEvents: [String]) {}

    func receive(_ event: Event) {
        receivedEvents.append(event.name)
    }
}
