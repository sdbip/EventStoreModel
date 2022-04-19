/// An entity is a thing that we want to track over time. We track it because we are interested in
// its state. It may be meaningful to refer to entities that “never” change (like nations or
/// departments) but such entities can probably just be referred to as simple names. They do not
/// need this protocol.
public protocol Entity {

    /// A type identifier, used to detect when trying to reconstitute an entity
    /// of the wrong type.
    ///
    /// Note to implementor: While multiple types with the same id are allowed,
    /// such a situation will have no way to detect erroneous references.
    static var type: String { get }

    /// A unique identifier for this entity.
    ///
    /// Note to implementor: This property should be immutable and always
    /// return the same value that was passed to the initializer.
    var id: String { get }

    /// Used to detect concurrent changes to the same entity. If the
    /// version has changed in the database since reconstituting this
    /// entity, it is not safe to publish the changes.
    ///
    /// Note to implementor: This property should be immutable and always
    /// return the same value that was passed to the initializer.
    var version: EntityVersion { get }

    /// All events that need to be published to persist the changes since
    /// the entity was reconstituted.
    var unpublishedEvents: [UnpublishedEvent] { get }

    init(id: String, version: EntityVersion)

    /// Applies a published event to update the current state of the entity
    func apply(_ event: PublishedEvent)

}
