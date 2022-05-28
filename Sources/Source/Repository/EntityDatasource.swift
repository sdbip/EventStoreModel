public protocol EntityDatasource {
    func type(ofEntityRowWithId id: String) throws -> String?

    func entityRow(withId id: String) throws -> EntityRow?
    func allEventRows(forEntityWithId entityId: String) throws -> [EventRow]
}
