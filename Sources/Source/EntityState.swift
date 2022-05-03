public protocol EntityState: AnyObject {

    /// A type identifier, used to detect when trying to reconstitute an entity
    /// of the wrong type.
    ///
    /// Note to implementor: While multiple types with the same id are allowed,
    /// such a situation will have no way to detect erroneous references.
    static var type: String { get }

    /// All events that need to be published to persist the changes since
    /// the entity was reconstituted.
    var unpublishedEvents: [UnpublishedEvent] { get }

    init()

    /// Applies a published event to update the current state of the entity
    func apply(_ event: PublishedEvent)

}
