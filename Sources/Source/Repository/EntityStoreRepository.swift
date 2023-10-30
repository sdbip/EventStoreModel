public protocol EntityStoreRepository {
    func typeId(entityRowWithId id: String) throws -> String?

    func entityRow(id: String) throws -> EntityRow?
    func allEventRows(entityId: String) throws -> [EventRow]
}
