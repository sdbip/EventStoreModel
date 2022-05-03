/// An entity is a thing that we want to track over time. During that time its
/// `state` tends to change. While there are some entities that “never” change,
/// they are not relevant for this model.
///
/// The `state` of this entity represents an instant in time for when (if ever)
/// it was last persisted, and any additional  changes that haven't yet been.
///
/// An entity is persisted with a `version` number, which is used to detect
/// concurrent updates to its `state`. The version is read when reconstituted,
/// and again when changes are published. If the values are not equal, the
/// changes are not safe to publish.
public struct Entity<StateType> where StateType: EntityState {

    /// A unique identifier for this entity.
    public let id: String

    /// Used to detect concurrent changes to the same entity. If the version
    /// has changed in the database after it was reconstituted, it will not be
    /// safe to publish changes to the `state`.
    public let version: EntityVersion

    /// The current (known) state of this entity. The state at the time it was
    /// reconstituted, plus any not yet persisted changes.
    public let state: StateType

    public init(id: String, version: EntityVersion) {
        self.id = id
        self.version = version

        state = StateType()
    }

}
