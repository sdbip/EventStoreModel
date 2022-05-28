public protocol EventDatasource {
    func insertEntityRow(id: String, type: String, version: Int32) throws

    func insertEventRow(entityId: String, entityType: String, name: String, jsonDetails: String, actor: String, version: Int32, position: Int64) throws

    func nextPosition() throws -> Int64
    func setNextPosition(_ position: Int64) throws

    func version(ofEntityRowWithId id: String) throws -> Int32?
    func setVersion(_ version: Int32, onEntityRowWithId id: String) throws
}
