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

            if case .version(let v) = entity.version {
                try connection.updateVersion(ofEntityWithId: entity.id, to: Int32(events.count) + v)
            } else {
                try connection.addEntity(id: entity.id, type: EntityType.type, version: Int32(events.count) - 1)
            }

            var nextPosition = try connection.nextPosition()
            try connection.incrementPosition(nextPosition + Int64(events.count))

            var nextVersion = entity.version.next
            for event in events {
                try connection.publish(event, entityId: entity.id, actor: actor, version: nextVersion, position: nextPosition)
                nextVersion += 1
                nextPosition += 1
            }
        }
    }

    public func publish(_ event: UnpublishedEvent, forId id: String, type: String, actor: String) throws {

        let connection = try Connection(openFile: dbFile)

        try connection.transaction {
            let currentVersion = try connection.version(ofEntityWithId: id)

            if case .some(let v) = currentVersion {
                try connection.updateVersion(ofEntityWithId: id, to: v + 1)
            } else {
                try connection.addEntity(id: id, type: type, version: 0)
            }

            let nextPosition = try connection.nextPosition()
            try connection.incrementPosition(nextPosition + 1)

            let nextVersion = (currentVersion ?? -1) + 1
            try connection.publish(event, entityId: id, actor: actor, version: nextVersion, position: nextPosition)
        }
    }
}

private extension Connection {
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
            case .version(let v): expectedVersion = v
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
