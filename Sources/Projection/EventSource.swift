public final class EventSource {
    private let database: Database
    private let delegate: PositionDelegate?
    private var receptacles: [Receptacle] = []
    private var lastProjectedPosition: Int64?

    public init(database: Database, delegate: PositionDelegate? = nil) {
        self.database = database
        self.delegate = delegate
        self.lastProjectedPosition = delegate?.initialPosition
    }

    public func add(_ receptacle: Receptacle) {
        receptacles.append(receptacle)
    }

    public func projectEvents(count: Int) throws {
        let events = try nextEvents(count: count)
        for event in events {
            for receptacle in receptacles.filter({ $0.handledEvents.contains(event.name) }) {
                receptacle.receive(event)
            }
            lastProjectedPosition = event.position
            delegate?.update(position: event.position)
        }
    }

    private func nextEvents(count: Int) throws -> [Event] {
        return try database.readEvents(maxCount: count, after: lastProjectedPosition)
    }
}

public protocol Database {
    func readEvents(maxCount: Int, after position: Int64?) throws -> [Event]
}

public protocol Receptacle {
    var handledEvents: [String] { get }
    func receive(_ event: Event)
}
