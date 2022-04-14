public protocol Entity {

    /// A unique identifier used to detect when trying to reconstitute
    /// an entity of the wrong type.
    static var type: String { get }

    /// Used to detect concurrent changes to the same entity. If the
    /// version has changed in the database since reconstituting this
    /// entity, it is not safe to publish the changes.
    ///
    /// Note to implementor: This property should be immutable and always
    /// return the same value that was passed to the initializer.
    var version: EntityVersion { get }

    /// All events that need to be published to persist the changes since
    // the entity was reconstituted.
    var unpublishedEvents: [UnpublishedEvent] { get }

    init(version: EntityVersion)

    /// Applies a published event to update the current state of the entity
    func apply(_ event: PublishedEvent)

}
