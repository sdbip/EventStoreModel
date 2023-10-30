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
    /// name that isn't used by any other entity implementation. The name of
    /// the conforming type may be a good rule of thumb.
    ///
    /// ```
    /// public class MyEntity: Entity {
    ///     public static let typeId = #{"MyEntity"}#
    ///     // Futher implementation
    /// }
    /// ```
    ///
    /// Note, however, that if you change the name of your type, the `typeId`
    /// property must remain the same or it will no longer match the stored
    /// entities in the database, and you will not be able to reconstitute
    /// them anymore.
    ///
    /// It is technically allowed to duplicate the `typeId` property for
    /// multiple entities, but it serioulsy diminishes the ability to detect
    /// errors.
    static var typeId: String { get }

    /// Identification for the snapshot that stores the current state
    var snapshotId: SnapshotId { get }

    /// All events that need to be published to persist the current state.
    var unpublishedEvents: [UnpublishedEvent] { get }

    /// Initializes a specific version of an entity.
    init(snapshotId: SnapshotId)

    func replay(_ event: PublishedEvent)
}

extension Entity {
    public var id: String { snapshotId.entityId }
    public var version: EntityVersion { snapshotId.version }
}

public struct SnapshotId {

    /// A unique identifier for this entity.
    public let entityId: String

    /// Optimistic concurrency guard. If the stored version has changed after
    /// this instance was reconstituted, publishing changes to it will not be
    /// allowed. The changes done to this instance will be discarded.
    public let version: EntityVersion

    public init(entityId: String, version: EntityVersion = .notSaved) {
        self.entityId = entityId
        self.version = version
    }

}

extension SnapshotId : ExpressibleByStringLiteral {
    public init(stringLiteral value: StringLiteralType) {
        self.init(entityId: value)
    }
}
