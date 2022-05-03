public extension Database {
    func nextPosition() throws -> Int64 {
        try operation("SELECT value FROM Properties WHERE name = 'next_position'")
            .single(read: { $0.int64(at: 0) })!
    }

    func setNextPosition(_ position: Int64) throws {
        try operation("UPDATE Properties SET value = ? WHERE name = 'next_position'", position)
            .execute()
    }
}
