public final class EventSource {
    let database: Database
    var receptacle: Receptacle?

    public init(database: Database) {
        self.database = database
    }

    public func add(_ receptacle: Receptacle) {
        self.receptacle = receptacle
    }

    public func projectEvents(count: Int) throws {
        if let event = database.nextEvent {
            receptacle?.receive(event)
        }
    }
}

public protocol Database {
    var nextEvent: Event? { get }
}

public protocol Receptacle {
    func receive(_ event: Event)
}
