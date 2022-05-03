/// An entity is a thing that we want to track over time. We track it because we are interested in
/// its state. It may be meaningful to refer to entities that “never” change (like nations or
/// departments) but such entities can probably just be referred to as simple names. They do not
/// need this protocol.
public struct Entity<State> where State: EntityState {

    /// A unique identifier for this entity.
    ///
    /// Note to implementor: This property should be immutable and always
    /// return the same value that was passed to the initializer.
    public let id: String

    /// Used to detect concurrent changes to the same entity. If the
    /// version has changed in the database since reconstituting this
    /// entity, it is not safe to publish the changes.
    ///
    /// Note to implementor: This property should be immutable and always
    /// return the same value that was passed to the initializer.
    public let version: EntityVersion

    public let state: State

    public init(id: String, version: EntityVersion) {
        self.id = id
        self.version = version

        state = State()
    }

}
