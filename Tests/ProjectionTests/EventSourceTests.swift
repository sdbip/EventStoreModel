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
        let receptacle = TestReceptacle(handledEvents: ["TheEvent"])
        eventSource.add(receptacle)
        database.nextEvents = [event(named: "UnhandledEvent")]

        try eventSource.projectEvents(count: 1)

        XCTAssertEqual(receptacle.receivedEvents, [])
    }

    func testAllowsEmpty() throws {
        let receptacle = TestReceptacle(handledEvents: ["TheEvent"])
        eventSource.add(receptacle)
        database.nextEvents = []

        try eventSource.projectEvents(count: 1)

        XCTAssertEqual(receptacle.receivedEvents, [])
    }

    func testForwardsEventToReceiver() throws {
        let receptacle = TestReceptacle(handledEvents: ["TheEvent"])
        eventSource.add(receptacle)
        database.nextEvents = [event(named: "TheEvent")]

        try eventSource.projectEvents(count: 1)

        XCTAssertEqual(receptacle.receivedEvents, ["TheEvent"])
    }

    func testForwardsMultipleEvents() throws {
        let receptacle = TestReceptacle(handledEvents: ["TheFirstEvent", "TheSecondEvent"])
        eventSource.add(receptacle)
        database.nextEvents = [event(named: "TheFirstEvent"), event(named: "TheSecondEvent")]

        try eventSource.projectEvents(count: 2)

        XCTAssertEqual(receptacle.receivedEvents, ["TheFirstEvent", "TheSecondEvent"])
    }

    func testForwardsOnlyAsManyEventsAsIndicated() throws {
        let receptacle = TestReceptacle(handledEvents: ["TheFirstEvent", "TheSecondEvent"])
        eventSource.add(receptacle)
        database.nextEvents = [event(named: "TheFirstEvent", position: 0), event(named: "TheSecondEvent", position: 1)]

        try eventSource.projectEvents(count: 1)

        XCTAssertEqual(receptacle.receivedEvents, ["TheFirstEvent"])
    }

    func testReadsOnlyEventsAfterTheCurrentPosition() throws {
        eventSource = EventSource(database: database, lastProjectedPosition: 1)

        let receptacle = TestReceptacle(handledEvents: ["TheFirstEvent", "TheSecondEvent"])
        eventSource.add(receptacle)
        database.nextEvents = [
            event(named: "TheFirstEvent", position: 1),
            event(named: "TheSecondEvent", position: 2)
        ]

        try eventSource.projectEvents(count: 2)

        XCTAssertEqual(receptacle.receivedEvents, ["TheSecondEvent"])
    }

    func testUpdatesPositionAdfterReadingEvents() throws {
        let receptacle = TestReceptacle(handledEvents: ["TheFirstEvent", "TheSecondEvent"])
        eventSource.add(receptacle)
        database.nextEvents = [
            event(named: "TheFirstEvent", position: 1),
            event(named: "TheSecondEvent", position: 2)
        ]

        try eventSource.projectEvents(count: 1)
        try eventSource.projectEvents(count: 1)

        XCTAssertEqual(receptacle.receivedEvents, ["TheFirstEvent", "TheSecondEvent"])
    }

    private func event(named name: String) -> Event {
        event(named: name, position: 0)
    }

    private func event(named name: String, position: Int64) -> Event {
        Event(
            entityId: "some_entity",
            name: name,
            entityType: "some_type",
            details: "{}",
            position: position)
    }
}

final class MockDatabase: Database {
    var nextEvents: [Event] = []

    func readEvents(count: Int, after position: Int64?) -> [Event] {
        return Array(nextEvents.drop(while: {position != nil && $0.position <= position!}).prefix(count))
    }
}

final class TestReceptacle: Receptacle {
    let handledEvents: [String]
    var receivedEvents: [String] = []

    init(handledEvents: [String]) {
        self.handledEvents = handledEvents
    }

    func receive(_ event: Event) {
        receivedEvents.append(event.name)
    }
}
