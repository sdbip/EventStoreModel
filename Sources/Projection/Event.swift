/// <summary>An event notifying that the state of an entity has changed at the source</summary>
public struct Event {
    /// <summary>The id of the entity that changed</summary>
    public let entityId: String
    /// <summary>The type of entity publishing this event, used as a namespace for duplicated event names</summary>
    public let entityType: String
    /// <summary>The name of the event, indicating in what way the entity's state has changed</summary>
    public let name: String
    /// <summary>A JSON object specifying the details of the change</summary>
    public let jsonDetails: String
    /// <summary>The position of this event in the stream. Useful for keeping track after restarting the application</summary>
    public let position: Int64

    public init(entityId: String, name: String, entityType: String, details: String, position: Int64) {
        self.entityId = entityId;
        self.name = name;
        self.entityType = entityType;
        self.jsonDetails = details;
        self.position = position;
    }
}
