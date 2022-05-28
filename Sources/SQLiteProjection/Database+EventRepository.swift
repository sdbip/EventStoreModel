import SQLite
import Projection

extension Database: EventRepository {
    public func readEvents(maxCount: Int, after position: Int64?) throws -> [Event] {
        let operation = try operation("""
            SELECT "entityId", "entityType", "name", "details", "position" FROM "Events" WHERE "position" > $1 LIMIT \(maxCount)
            """,
            position ?? -1)
        return try events(from: operation)
    }

    public func readEvents(at position: Int64) throws -> [Event] {
        let operation = try operation("""
            SELECT "entityId", "entityType", "name", "details", "position" FROM "Events" WHERE "position" = $1
            """,
            position)
        return try events(from: operation)
    }

    private func events(from operation: Operation) throws -> [Event] {
        return try operation.query {
            guard let entityId = $0.string(at: 0),
                  let type = $0.string(at: 1),
                  let name = $0.string(at: 2),
                  let details = $0.string(at: 3)
            else { throw SQLiteError.unknown }
            
            return Event(
                entity: Entity(id: entityId, type: type),
                name: name,
                details: details,
                position: $0.int64(at: 4))
        }
    }
}
