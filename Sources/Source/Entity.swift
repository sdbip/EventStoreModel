/// An entity is a thing that we want to track over time. During that time its
/// state tends to change. While there are some entities that “never” change,
/// they are not relevant for this model.
///
/// The state of this entity is represented as a sequence of events. Some
/// are published (and therefore official) while others only apply to this one
/// instance until they can be published.
public protocol Entity {

    /// A unique identifier for the conforming type, used to detect when trying
    /// to reconstitute an entity of the wrong type. This should be a unique
    /// name that isn't used by any other entity type. The actual name of
    /// the conforming type may be a good rule of thumb.
    ///
    /// ```
    /// public class MyEntity: EntityState {
    ///     public static let typeId = #{"MyEntity"}#
    ///     // Futher implementation
    /// }
    /// ```
    ///
    /// Note, however, that if you change the name of your type, the `type`
    /// property must remain the same or it will no longer match the stored
    /// entities in the database, and you will not be able to reconstitute
    /// them anymore.
    ///
    /// It is technically allowed to duplicate the `type` property for
    /// multiple entities, but it serioulsy diminishes the ability to detect
    /// errors.
    static var typeId: String { get }

    /// A unique identifier for this entity.
    var reconstitution: ReconstitutionData { get }

    /// All events that need to be published to persist the current state.
    var unpublishedEvents: [UnpublishedEvent] { get }

    /// Initializes the state from already published events. Events may be
    /// ignored if they have no effect on the behaviour of the entity.
    ///
    /// An event might prevent certain future operations, or it may affect
    /// how those operations change the state. Such events will probably
    /// set some flags or even remember specific data so they can be
    /// referenced when said operations are performed.
    ///
    /// Other events might only exist to feed data to a projection. Such
    /// events can be ignored entirely here.
    init(reconstitution: ReconstitutionData)

    func replay(_ event: PublishedEvent)
}

extension Entity {
    public var id: String { reconstitution.id }
    public var version: EntityVersion { reconstitution.version }
}

public struct ReconstitutionData {

    /// A unique identifier for this entity.
    public let id: String

    /// Optimistic concurrency guard. If the stored version has changed after
    /// this instance was reconstituted, publishing changes to it will not be
    /// allowed. The changes done to this instance will be discarded.
    public let version: EntityVersion

    public init(id: String, version: EntityVersion = .notSaved) {
        self.id = id
        self.version = version
    }

}
