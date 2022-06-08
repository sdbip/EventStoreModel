/// An entity is a thing that we want to track over time. During that time its
/// state tends to change. While there are some entities that “never” change,
/// they are not relevant for this model.
///
/// The `state` of this entity is represented as a sequence of events. Some
/// are published (and therefore official) while others only apply to this one
/// instance until they can be published.
public struct Entity<StateType> where StateType: EntityState {

    /// A unique identifier for this entity.
    public let id: String

    /// Optimistic concurrency guard. If the stored version has changed after
    /// this instance was reconstituted, publishing changes to it will not be
    /// allowed. The changes done to this instance will be discarded.
    public let version: EntityVersion

    /// The main part of your entity. Your invariants and other business rules
    /// should be defined here.
    public let state: StateType

    public init(id: String, state: StateType, version: EntityVersion = .notSaved) {
        self.id = id
        self.version = version
        self.state = state
    }

}
