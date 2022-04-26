import Projection
import SQLite

private let baseQuery = "SELECT entity, name, details, position FROM Events"

public final class SQLiteDatabase: Database {
    private let file: String

    public init(file: String) {
        self.file = file
    }

    public func readEvents(count: Int, after position: Int64?) throws -> [Event] {
        let connection = try Connection(openFile: file)
        let operation: Operation
        if let position = position {
            operation = try connection.operation(
                "\(baseQuery) WHERE position > ?",
                position)
        } else {
            operation = try connection.operation(baseQuery)
        }
        return try events(from: operation)
    }
    
    public func readEvents(at position: Int64) throws -> [Event] {
        let connection = try Connection(openFile: file)
        let operation = try connection.operation(
            "\(baseQuery) WHERE position = ?",
            position)
        return try events(from: operation)
    }
    
    private func events(from operation: Operation) throws -> [Event] {
        return try operation.query {
            let entityId = $0.string(at: 0)
            let name = $0.string(at: 1)
            let details = $0.string(at: 2)
            let position = $0.int64(at: 3)
            return Event(entityId: entityId!, name: name!, entityType: "type", details: details!, position: position)
        }
    }
}
