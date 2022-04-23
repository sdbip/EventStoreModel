public final class EventSource {
    private let database: Database
    private var receptacle: Receptacle?
    private var lastProjectedPosition: Int64?

    public init(database: Database, lastProjectedPosition: Int64? = nil) {
        self.database = database
        self.lastProjectedPosition = lastProjectedPosition
    }

    public func add(_ receptacle: Receptacle) {
        self.receptacle = receptacle
    }

    public func projectEvents(count: Int) throws {
        let events = database.readEvents(count: count, after: lastProjectedPosition)
        for event in events {
            receptacle?.receive(event)
            lastProjectedPosition = event.position
        }
    }
}

public protocol Database {
    func readEvents(count: Int, after position: Int64?) -> [Event]
}

public protocol Receptacle {
    func receive(_ event: Event)
}
