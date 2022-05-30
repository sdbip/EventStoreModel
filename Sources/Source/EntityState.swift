/// The state of an entity.
public protocol EntityState: AnyObject {

    /// A unique identifier for this type, used to detect when trying to
    /// reconstitute an entity of the wrong type.
    ///
    /// Note to implementor: While multiple types with the same id are
    /// technically allowed, it will eliminate the ability to detect errors.
    static var typeId: String { get }

    /// All events that need to be published to persist the changes since the
    /// entity was reconstituted.
    var unpublishedEvents: [UnpublishedEvent] { get }

    /// Replays a published event to update the current state of the entity, so
    /// that the correct behaviour can be enforced. This can be ignored if the
    /// entity's behaviour is not affected by the change.
    init(events: [PublishedEvent])

}
