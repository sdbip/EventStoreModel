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

    func allEventRows(forEntityWithId entityId: String) throws -> [EventRow] {
        return try operation("SELECT entityType, name, details, actor, timestamp FROM Events WHERE entityId = ? ORDER BY version", entityId)
            .query {
                guard let type = $0.string(at: 0) else { throw SQLiteError.message("Event has no entityType") }
                guard let name = $0.string(at: 1) else { throw SQLiteError.message("Event has no name") }
                guard let details = $0.string(at: 2) else { throw SQLiteError.message("Event has no details") }
                guard let actor = $0.string(at: 3) else { throw SQLiteError.message("Event has no actor") }
                let entity = EntityData(id: entityId, type: type)
                return EventRow(entity: entity, name: name, details: details, actor: actor, timestamp: $0.date(at: 4))
            }
    }
}
