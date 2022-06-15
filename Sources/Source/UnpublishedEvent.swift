import Foundation

/// An unpublished event, representing in-memory changes to an ``Entity``.
/// This event must be published to be made official.
public struct UnpublishedEvent {
    /// A name identifying how the ``Entity`` changed
    public let name: String
    /// JSON-formatted data detailing the specifics of the change
    public let jsonDetails: String

    /// Initializes an ``UnpublishedEvent`` with JSON formatted details.
    ///
    /// Can fail if the supplied details ``String`` is not valid JSON.
    /// Use ``init(name:encodableDetails:)`` if you wish the JSON to be
    /// geerated for you.
    ///
    /// - Parameters:
    ///   - name: A name identifying how the ``Entity`` changed
    ///   - details: JSON-formatted data detailing the specifics of the change
    ///
    /// - Returns: nil if the details are not valid JSON
    public init?(name: String, details: String) {
        guard let data = details.data(using: .utf8) else { return nil }
        guard let _ = try? JSONSerialization.jsonObject(with: data) else { return nil }

        self.name = name
        self.jsonDetails = details
    }

    /// Initializes an ``UnpublishedEvent`` with the JSON representation of
    /// the event details, and using ``Details.eventName`` as the name of the
    /// event
    ///
    /// - Parameters:
    ///   - encodableDetails: A data structure detailing the specifics of the change
    ///
    /// - Throws: If the data structure cannot be parsed as JSON (eg. if it
    ///    contains cyclic references)
    public init<Details>(encodableDetails details: Details) throws where Details: Encodable&EventDetails {
        try self.init(name: Details.eventName, encodableDetails: details)
    }

    /// Initializes an ``UnpublishedEvent`` with the JSON representation of
    /// the event details.
    ///
    /// - Parameters:
    ///   - name: A name identifying how the ``Entity`` changed
    ///   - encodableDetails: A data structure detailing the specifics of the change
    ///
    /// - Throws: If the data structure cannot be parsed as JSON (eg. if it
    ///    contains cyclic references)
    public init<Details>(name: String, encodableDetails details: Details) throws where Details: Encodable {
        let encodedDetails = try JSONEncoder().encode(details)
        guard let details = String(data: encodedDetails, encoding: .utf8) else { throw EncodingError.notUTF8 }

        self.name = name
        self.jsonDetails = details
    }
}

enum EncodingError: Error {
    case notUTF8
}
