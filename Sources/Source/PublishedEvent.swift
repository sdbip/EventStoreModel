import Foundation

/// A published event representing a past state change to an ``Entity``.
/// All the published events of an ``Entity``, taken in order, defines and
/// determines the current state of that entity.
public struct PublishedEvent {
    /// A name identifying how the ``Entity`` changed
    public let name: String
    /// JSON-formatted data detailing the specifics of the change
    public let jsonDetails: String
    /// The person or system that caused the change
    public let actor: String
    /// The exact time this event was persisted.
    public let timestamp: Date

    public init(name: String, details: String, actor: String, timestamp: Date) {
        self.name = name
        self.jsonDetails = details
        self.actor = actor
        self.timestamp = timestamp
    }

    /// Parse the ``jsonDetails`` as a structured type that conforms to ``Decodable``.
    /// - Parameters:
    ///   - type: the structured type the details should be referenced as
    /// - Returns: The parsed data structure
    /// - Throws: If parsing fails
    public func details<T>(as type: T.Type) throws -> T where T: Decodable {
        return try JSONDecoder().decode(T.self, from: jsonDetails.data(using: .utf8)!)
    }
}
