import Postgres
import Projection

extension Database: EventRepository {
    public func readEvents(maxCount: Int, after position: Int64?) throws -> [Event] {
        let operation = try operation("""
            SELECT "entityId", "entityType", "name", "details", "position" FROM "Events" WHERE "position" > $1 LIMIT \(maxCount)
            """,
            parameters: Int(position ?? -1))
        return try events(from: operation)
    }

    private func events(from operation: Operation) throws -> [Event] {
        return try operation.query {
            return try Event(
                entity: Entity(id: $0[0].string(), type: $0[1].string()),
                name: $0[2].string(),
                details: $0[3].string(),
                position: Int64($0[4].int()))
        }
    }
}
