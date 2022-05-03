public extension Database {
    func entityRow(withId id: String) throws -> EntityRow? {
        return try operation("SELECT type, version FROM Entities WHERE id = ?", id)
        .single {
            guard let type = $0.string(at: 0) else { throw SQLiteError.message("Entity has no type") }
            return EntityRow(id: id, type: type, version: $0.int32(at: 1))
        }
    }

    func insertEntityRow(id: String, type: String, version: Int32) throws {
        try operation("INSERT INTO Entities (id, type, version) VALUES (?, ?, ?)", id, type, version)
            .execute()
    }

    func type(ofEntityRowWithId id: String) throws -> String? {
        return try operation("SELECT type FROM Entities WHERE id = 'test'")
            .single { $0.string(at: 0) }
    }

    func version(ofEntityRowWithId id: String) throws -> Int32? {
        return try operation("SELECT version FROM Entities WHERE id = ?", id)
            .single(read: { $0.int32(at: 0) })
    }

    func setVersion(_ version: Int32, onEntityRowWithId id: String) throws {
        try operation("UPDATE Entities SET version = ? WHERE id = ?", version, id)
            .execute()
    }
}
