public struct Entity {
    /// <summary>The id of the entity</summary>
    public let id: String
    /// <summary>The type of the entity</summary>
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
