/// <summary>An event notifying that the state of an entity has changed at the source</summary>
public struct Event {
    /// <summary>The entity that changed</summary>
    public let entity: Entity
    /// <summary>The name of the event, indicating in what way the entity's state has changed</summary>
    public let name: String
    /// <summary>A JSON object specifying the details of the change</summary>
    public let jsonDetails: String
    /// <summary>The position of this event in the stream. Useful for keeping track after restarting the application</summary>
    public let position: Int64

    public init(entity: Entity, name: String, details: String, position: Int64) {
        self.entity = entity;
        self.name = name;
        self.jsonDetails = details;
        self.position = position;
    }
}
