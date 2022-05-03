import Foundation

public struct EntityId {
    public let id: String
    public let type: String

    init(id: String, type: String) {
        self.id = id
        self.type = type
    }
}

public struct EntityData {
    public let id: String
    public let type: String
    public let version: Int32

    init(id: String, type: String, version: Int32) {
        self.id = id
        self.type = type
        self.version = version
    }
}

public struct EventData {
    public let entity: EntityId
    public let name: String
    public let details: String
    public let actor: String
    public let timestamp: Date

    init(entity: EntityId, name: String, details: String, actor: String, timestamp: Date) {
        self.entity = entity
        self.name = name
        self.details = details
        self.actor = actor
        self.timestamp = timestamp
    }
}

public extension Database {
    func nextPosition() throws -> Int64 {
        try operation("SELECT value FROM Properties WHERE name = 'next_position'")
            .single(read: { $0.int64(at: 0) })!
    }

    func setPosition(_ position: Int64) throws {
        try operation("UPDATE Properties SET value = ? WHERE name = 'next_position'", position)
            .execute()
    }
}

public extension Database {
    func entity(withId id: String) throws -> EntityData? {
        return try operation("SELECT type, version FROM Entities WHERE id = ?", id)
        .single {
            guard let type = $0.string(at: 0) else { throw SQLiteError.message("Entity has no type") }
            return EntityData(id: id, type: type, version: $0.int32(at: 1))
        }
    }

    func type(ofEntityWithId id: String) throws -> String? {
        return try operation("SELECT type FROM Entities WHERE id = 'test'")
            .single { $0.string(at: 0) }
    }

    func version(ofEntityWithId id: String) throws -> Int32? {
        return try operation("SELECT version FROM Entities WHERE id = ?", id)
            .single(read: { $0.int32(at: 0) })
    }

    func insertEntity(id: String, type: String, version: Int32) throws {
        try operation("INSERT INTO Entities (id, type, version) VALUES (?, ?, ?)", id, type, version)
            .execute()
    }

    func updateVersion(ofEntityWithId id: String, to version: Int32) throws {
        try operation("UPDATE Entities SET version = ? WHERE id = ?", version, id)
            .execute()
    }
}

public extension Database {
    func insertEvent(entityId: String, entityType: String, name: String, jsonDetails: String, actor: String, version: Int32, position: Int64) throws {
        try operation("INSERT INTO Events (entityId, entityType, name, details, actor, version, position) VALUES (?, ?, ?, ?, ?, ?, ?)",
            entityId,
            entityType,
            name,
            jsonDetails,
            actor,
            version,
            position
        ).execute()
    }
    
    func allEvents(forEntityWithId entityId: String) throws -> [EventData] {
        return try self.operation("SELECT entityType, name, details, actor, timestamp FROM Events WHERE entityId = ? ORDER BY version", entityId)
            .query {
                guard let type = $0.string(at: 0) else { throw SQLiteError.message("Event has no entityType") }
                guard let name = $0.string(at: 1) else { throw SQLiteError.message("Event has no name") }
                guard let details = $0.string(at: 2) else { throw SQLiteError.message("Event has no details") }
                guard let actor = $0.string(at: 3) else { throw SQLiteError.message("Event has no actor") }
                let entity = EntityId(id: entityId, type: type)
                return EventData(entity: entity, name: name, details: details, actor: actor, timestamp: $0.date(at: 4))
            }
    }
}
