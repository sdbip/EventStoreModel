public extension Database {
    func insertEntityRow(id: String, type: String, version: Int32) throws {
        try operation("INSERT INTO Entities (id, type, version) VALUES (?, ?, ?)", id, type, version)
            .execute()
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
