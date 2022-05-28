import Source

public extension Database {
    func insertEventRow(entityId: String, entityType: String, name: String, jsonDetails: String, actor: String, version: Int32, position: Int64) throws {
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
}
