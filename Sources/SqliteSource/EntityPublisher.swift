import Foundation

import Source
import SQLite

public struct EntityPublisher {
    private let dbFile: String

    public init(dbFile: String) {
        self.dbFile = dbFile
    }

    public func publishChanges<EntityType>(entity: EntityType, actor: String) throws where EntityType: Entity {
        let connection = try Connection(openFile: dbFile)

        try connection.transaction {
            let statement = try Statement(
                prepare: "SELECT version FROM Entities WHERE id = ?",
                connection: connection)
            statement.bind(entity.id, to: 1)

            let version = try statement.single(read: { $0.int32(at: 0) })

            switch (entity.version, version) {
                case (.notSaved, nil): try connection.add(entity)
                case (.version(let v1), let v2) where v1 == v2: try connection.updateVersion(of: entity, version: (version ?? -1) + Int32(entity.unpublishedEvents.count))
                default: throw SQLiteError.message("Concurrency Error")
            }

            var eventVersion = 1 + (version ?? -1)
            for event in entity.unpublishedEvents {
                try connection.publish(event, entityId: entity.id, version: eventVersion, actor: actor)
                eventVersion += 1
            }
        }
    }
}

private extension Connection {
    func add<EntityType>(_ entity: EntityType) throws where EntityType: Entity {
        let statement = try Statement(prepare: """
            INSERT INTO Entities (id, type, version)
            VALUES (?, ?, ?);
            """,
            connection: self)
        statement.bind(entity.id, to: 1)
        statement.bind(EntityType.type, to: 2)
        statement.bind(0, to: 3)
        try statement.execute()
    }

    func updateVersion(of entity: Entity, version: Int32) throws {
        let statement = try Statement(
            prepare: "UPDATE Entities SET version = ? WHERE id = ?",
            connection: self
        )
        statement.bind(version, to: 1)
        statement.bind(entity.id, to: 2)
        try statement.execute()
    }

    func publish(_ event: UnpublishedEvent, entityId: String, version: Int32, actor: String) throws {
        let statement = try Statement(prepare: """
            INSERT INTO Events (entity, name, details, actor, version, position)
            VALUES (?, ?, ?, ?, ?, ?);
            """,
            connection: self)
        statement.bind(entityId, to: 1)
        statement.bind(event.name, to: 2)
        statement.bind(event.details, to: 3)
        statement.bind(actor, to: 4)
        statement.bind(version, to: 5)
        statement.bind(0, to: 6)
        try statement.execute()
    }
}
