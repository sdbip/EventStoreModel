/// An entity tracked by the Source system
public struct Entity {
    /// The id of the entity
    public let id: String
    /// The type of the entity
    public let type: String

    public init(id: String, type: String) {
        self.id = id
        self.type = type
    }
}

extension Entity: Equatable {
    public static func ==(left: Entity, right: Entity) -> Bool {
        return left.id == right.id &&
        left.type == right.type
    }
}
