public struct EntityRow {
    public let id: String
    public let type: String
    public let version: Int32

    init(id: String, type: String, version: Int32) {
        self.id = id
        self.type = type
        self.version = version
    }
}
