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
        let events = database.readEvents(count: count)
        for event in events {
            receptacle?.receive(event)
        }
    }
}

public protocol Database {
    func readEvents(count: Int) -> [Event]
}

public protocol Receptacle {
    func receive(_ event: Event)
}
