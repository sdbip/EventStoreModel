public extension Database {
    func version(ofEntityWithId id: String) throws -> Int32? {
        return try self
            .operation("SELECT version FROM Entities WHERE id = ?", id)
            .single(read: { $0.int32(at: 0) })
    }

    func nextPosition() throws -> Int64 {
        try self.operation("SELECT value FROM Properties WHERE name = 'next_position'")
            .single(read: { $0.int64(at: 0) })!
    }

    func setPosition(_ position: Int64) throws {
        try self
            .operation("UPDATE Properties SET value = ? WHERE name = 'next_position'", position)
            .execute()
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

    func insertEvent(entityId: String, name: String, jsonDetails: String, actor: String, version: Int32, position: Int64) throws {
        try self.operation("""
            INSERT INTO Events (entity, name, details, actor, version, position)
            VALUES (?, ?, ?, ?, ?, ?);
            """,
            entityId,
            name,
            jsonDetails,
            actor,
            version,
            position
        ).execute()
    }
}
