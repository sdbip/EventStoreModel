import Foundation

import Source
import SQLite

public struct EventPublisher {
    private let dbFile: String

    public init(dbFile: String) {
        self.dbFile = dbFile
    }

    public func publishChanges<EntityType>(entity: EntityType, actor: String) throws where EntityType: Entity {
        let database = try Database(openFile: dbFile)

        let events = entity.unpublishedEvents

        try database.transaction {
            guard try database.isUnchanged(entity) else { throw SQLiteError.message("Concurrency Error") }

            if case .eventCount(let count) = entity.version {
                try database.updateVersion(ofEntityWithId: entity.id, to: Int32(events.count) + count)
            } else {
                try database.addEntity(id: entity.id, type: EntityType.type, version: Int32(events.count))
            }

            var nextPosition = try database.nextPosition()
            try database.incrementPosition(nextPosition + Int64(events.count))

            var nextVersion = entity.version.next
            for event in events {
                try database.publish(event, entityId: entity.id, actor: actor, version: nextVersion, position: nextPosition)
                nextVersion += 1
                nextPosition += 1
            }
        }
    }

    public func publish(_ event: UnpublishedEvent, forId id: String, type: String, actor: String) throws {

        let database = try Database(openFile: dbFile)

        try database.transaction {
            let currentVersion = try database.version(ofEntityWithId: id) ?? -1

            if currentVersion >= 0 {
                try database.updateVersion(ofEntityWithId: id, to: currentVersion + 1)
            } else {
                try database.addEntity(id: id, type: type, version: 1)
            }

            let nextPosition = try database.nextPosition()
            try database.incrementPosition(nextPosition + 1)

            let nextVersion = currentVersion + 1
            try database.publish(event, entityId: id, actor: actor, version: nextVersion, position: nextPosition)
        }
    }
}

private extension Database {
    func version(ofEntityWithId id: String) throws -> Int32? {
        return try self
            .operation("SELECT version FROM Entities WHERE id = ?", id)
            .single(read: { $0.int32(at: 0) })
    }

    func nextPosition() throws -> Int64 {
        try self.operation("SELECT value FROM Properties WHERE name = 'next_position'")
            .single(read: { $0.int64(at: 0) })!
    }

    func incrementPosition(_ position: Int64) throws {
        try self
            .operation("UPDATE Properties SET value = ? WHERE name = 'next_position'", position)
            .execute()
    }

    func isUnchanged(_ entity: Entity) throws -> Bool {
        let expectedVersion: Int32?
        switch entity.version {
            case .notSaved: expectedVersion = nil
            case .eventCount(let count): expectedVersion = count
        }

        let currentVersion = try self.version(ofEntityWithId: entity.id)
        return expectedVersion == currentVersion
    }

    func addEntity(id: String, type: String, version: Int32) throws {
        try self.operation("""
            INSERT INTO Entities (id, type, version)
            VALUES (?, ?, ?);
            """,
            id,
            type,
            version
        ).execute()
    }

    func updateVersion(ofEntityWithId id: String, to version: Int32) throws {
        try self.operation(
            "UPDATE Entities SET version = ? WHERE id = ?",
            version,
            id
        ).execute()
    }

    func publish(_ event: UnpublishedEvent, entityId: String, actor: String, version: Int32, position: Int64) throws {
        try self.operation("""
            INSERT INTO Events (entity, name, details, actor, version, position)
            VALUES (?, ?, ?, ?, ?, ?);
            """,
            entityId,
            event.name,
            event.jsonDetails,
            actor,
            version,
            position
        ).execute()
    }
}
