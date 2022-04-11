public struct History {
    public let events: [PublishedEvent]

    public init(events: [PublishedEvent]) {
        self.events = events
    }

    public func reconstitute<EntityType: Entity>() -> EntityType {
        let entity = EntityType()
        for event in self.events { entity.apply(event) }
        return entity
    }
}
