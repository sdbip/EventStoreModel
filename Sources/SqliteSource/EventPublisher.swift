import Foundation

import Source
import SQLite

public struct EventPublisher {
    private let dbFile: String

    public init(dbFile: String) {
        self.dbFile = dbFile
    }

    public func publishChanges<EntityType>(entity: EntityType, actor: String) throws where EntityType: Entity {
        let connection = try Connection(openFile: dbFile)

        try connection.transaction {
            let currentVersion = try connection
                .operation("SELECT version FROM Entities WHERE id = ?", entity.id)
                .single(read: { $0.int32(at: 0) })

            switch (entity.version, currentVersion) {
                case (.notSaved, nil): try connection.addEntity(entity)
                case (.version(let v1), let v2) where v1 == v2: try connection.updateVersion(of: entity, version: (currentVersion ?? -1) + Int32(entity.unpublishedEvents.count))
                default: throw SQLiteError.message("Concurrency Error")
            }

            let currentPosition = try connection
                .operation("SELECT MAX(position) FROM Events WHERE entity = ?", entity.id)
                .single(read: { $0.int64(at: 0) })
            let nextPosition = 1 + (currentPosition ?? -1)

            var nextVersion = 1 + (currentVersion ?? -1)
            for event in entity.unpublishedEvents {
                try connection.publish(event, entityId: entity.id, actor: actor, version: nextVersion, position: nextPosition)
                nextVersion += 1
            }
        }
    }
}

private extension Connection {
    func addEntity<EntityType>(_ entity: EntityType) throws where EntityType: Entity {
        try self.operation(
            """
            INSERT INTO Entities (id, type, version)
            VALUES (?, ?, 0);
            """,
            entity.id,
            EntityType.type
        ).execute()
    }

    func updateVersion(of entity: Entity, version: Int32) throws {
        try self.operation(
            "UPDATE Entities SET version = ? WHERE id = ?",
            version,
            entity.id
        ).execute()
    }

    func publish(_ event: UnpublishedEvent, entityId: String, actor: String, version: Int32, position: Int64) throws {
        try self.operation(
            """
            INSERT INTO Events (entity, name, details, actor, version, position)
            VALUES (?, ?, ?, ?, ?, ?);
            """,
            entityId,
            event.name,
            event.details,
            actor,
            version,
            position
        ).execute()
    }
}
