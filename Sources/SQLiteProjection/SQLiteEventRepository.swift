import Projection
import SQLite

private typealias Clause = (position: Int64, operator: String)

public final class SQLiteEventRepository: EventRepository {
    private let file: String

    public init(file: String) {
        self.file = file
    }

    public func readEvents(maxCount: Int, after position: Int64?) throws -> [Event] {
        let operation = try self.operation(clause: after(position), limit: "LIMIT \(maxCount)")
        return try events(from: operation)
    }
    
    public func readEvents(at position: Int64) throws -> [Event] {
        return try events(at(position))
    }

    private func after(_ position: Int64?) -> Clause? {
        guard let position = position else { return nil }
        return (position: position, operator: ">")
    }

    private func at(_ position: Int64) -> Clause {
        (position: position, operator: "=")
    }

    private func events(_ clause: Clause?) throws -> [Event] {
        let operation = try self.operation(clause: clause)
        return try events(from: operation)
    }

    private func operation(clause: Clause? = nil, limit: String? = nil) throws -> Operation {
        let baseQuery = """
            SELECT entity, type, name, details, position FROM Events
                JOIN Entities ON Events.entity = Entities.id
            """

        let database = try Database(openFile: file)
        if let (position, op) = clause {
            return try database.operation(
                "\(baseQuery) WHERE position \(op) ? \(limit ?? "")",
                position)
        }
        return try database.operation("\(baseQuery) \(limit ?? "")")
    }
    
    private func events(from operation: Operation) throws -> [Event] {
        return try operation.query {
            guard let entityId = $0.string(at: 0),
                  let type = $0.string(at: 1),
                  let name = $0.string(at: 2),
                  let details = $0.string(at: 3)
            else { throw SQLiteError.unknown }
            
            return Event(
                entityId: entityId,
                name: name,
                entityType: type,
                details: details,
                position: $0.int64(at: 4))
        }
    }
}
