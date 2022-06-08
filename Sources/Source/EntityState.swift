/// The state of an ``Entity``. The object that represents your entity should
/// conform to this protocol. Your invariants and other business rules
/// should be defined by this object.
///
/// What is a valid state for the entity? Given a specific prior state
/// (published events), what should be the result of the next operation?
/// Should the operation be allowed?
///
/// Here is a template for an ``EntityState`` conformant class (with pseudo-
/// code for the parts you need to define yourself):
/// ```
/// public class MyEntity: EntityState {
///     public static let type = ["MyEntity"]
///     public var unpublishedEvents: [UnpublishedEvent] = []
///
///     // ... add the necessary properties needed to control behaviour
///
///     // Initialize the current state of an entity from its published events.
///     init(events: [PublishedEvents]) {
///         for event in events {
///             if event.name == ["an event that matters to the behaviour"] {
///                 // update the respective state information
///             } else if event.name == ["another event that matters"] {
///                 // update the respective state information
///             ) else {
///                 // Ignore events that do not affect behaviour
///             }
///         }
///     }
///
///     // Perform an operation on the current state of the entity. This should add unpublished events as necessary.
///     public func operation([parameters)] throws {
///         if [state does not allow this operation] { throw [an Error] }
///         if [state is a certain way] {
///             try unpublishedEvents.append(UnpublishedEvent(EventType1.eventName, EventType1([parameters]))
///             // update the state information if this change affects future behaviour
///         ) else if [state is another way] {
///             try unpublishedEvents.append(UnpublishedEvent(EventType2.eventName, EventType1([parameters]))
///             try unpublishedEvents.append(UnpublishedEvent(EventType3.eventName, EventType1([parameters]))
///             // update the state information if this change affects future behaviour
///         ) else {
///             // Sometimes operations do not have any effect on the state
///         )
///     )
///
///     // This structure stores the details of an "EventType1" change.
///     struct EventType1 {
///         static let eventName = ["EventType1"]
///         // ...
///     }
/// }
/// ```
public protocol EntityState: AnyObject {

    /// A unique identifier for the conforming type, used to detect when trying
    /// to reconstitute an entity of the wrong type. This should be a unique
    /// name that isn't used by any other entity type. The actual name of
    /// the conforming type may be a good rule of thumb.
    ///
    /// ```
    /// public class MyEntity: EntityState {
    ///     public static let type = "MyEntity"
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
    init(events: [PublishedEvent])

}
