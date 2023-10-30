/// Optional protocol that allows creating ``UnpublishedEvent`` without explicitly specifying the `name`.
/// Apply this protocol to the ``Encodable`` type
public protocol EventNaming {
    /// The name of the events that are associated with this details structure
    static var eventName: String { get }
}
