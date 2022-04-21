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

        let events = entity.unpublishedEvents

        try connection.transaction {
            guard try connection.isUnchanged(entity) else { throw SQLiteError.message("Concurrency Error") }

            switch entity.version {
                case .version(let v):
                    try connection.updateVersion(of: entity, to: Int32(events.count) + v)
                default:
                    try connection.addEntity(entity, version: Int32(events.count) - 1)
            }

            let nextPosition = try connection.nextPosition()
            try connection.incrementPosition()

            var nextVersion = entity.version.next
            for event in events {
                try connection.publish(event, entityId: entity.id, actor: actor, version: nextVersion, position: nextPosition)
                nextVersion += 1
            }
        }
    }
}

private extension Connection {
    func nextPosition() throws -> Int64 {
        try self.operation("SELECT value FROM Properties WHERE name = 'next_position'")
            .single(read: { $0.int64(at: 0) })!
    }

    func incrementPosition() throws {
        try self
            .operation("UPDATE Properties SET value = value + 1 WHERE name = 'next_position'")
            .execute()
    }

    func isUnchanged(_ entity: Entity) throws -> Bool {
        let expectedVersion: Int32?
        switch entity.version {
            case .notSaved: expectedVersion = nil
            case .version(let v): expectedVersion = v
        }

        let currentVersion = try self
            .operation("SELECT version FROM Entities WHERE id = ?", entity.id)
            .single(read: { $0.int32(at: 0) })

        return expectedVersion == currentVersion
    }

    func addEntity<EntityType>(_ entity: EntityType, version: Int32) throws where EntityType: Entity {
        try self.operation(
            """
            INSERT INTO Entities (id, type, version)
            VALUES (?, ?, ?);
            """,
            entity.id,
            EntityType.type,
            version
        ).execute()
    }

    func updateVersion(of entity: Entity, to version: Int32) throws {
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
