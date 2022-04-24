public final class EventSource {
    private let database: Database
    private var receptacles: [Receptacle] = []
    private var lastProjectedPosition: Int64?

    public init(database: Database, lastProjectedPosition: Int64? = nil) {
        self.database = database
        self.lastProjectedPosition = lastProjectedPosition
    }

    public func add(_ receptacle: Receptacle) {
        receptacles.append(receptacle)
    }

    public func projectEvents(count: Int) throws {
        let events = nextEvents(count: count)
        for event in events {
            for receptacle in receptacles.filter({ $0.handledEvents.contains(event.name) }) {
                receptacle.receive(event)
            }
            lastProjectedPosition = event.position
        }
    }

    private func nextEvents(count: Int) -> [Event] {
        let events = database.readEvents(count: count, after: lastProjectedPosition)
        if events.isEmpty || !events.allSatisfy({ $0.position == events[0].position }) { return events }

        return database.readEvents(at: events[0].position)
    }
}

public protocol Database {
    func readEvents(count: Int, after position: Int64?) -> [Event]
    func readEvents(at position: Int64) -> [Event]
}

public protocol Receptacle {
    var handledEvents: [String] { get }
    func receive(_ event: Event)
}
