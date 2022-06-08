import Foundation

/// An unpublished event, representing in-memory changes to an ``Entity``.
/// This event must be published to be made official.
public struct UnpublishedEvent {
    /// A name identifying how the ``Entity`` changed
    public let name: String
    /// JSON-formatted data detailing the specifics of the change
    public let jsonDetails: String

    /// Initializes an ``UnpublishedEvent``.
    ///
    /// ```
    /// unpublishedEvents.append(
    ///     UnpublishedEvent(
    ///         name: "ScoreIncreased",
    ///         details: #"{"addedPoints": 42}"#
    ///     )
    /// )
    /// ```

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

    /// Initializes an ``UnpublishedEvent``.
    ///
    /// The recommended pattern for addind  an``UnpublishedEvent`` to an
    /// ``Entity``:
    /// ```
    /// unpublishedEvents.append(
    ///     UnpublishedEvent(
    ///         name: ScoreIncreased.eventName,
    ///         details: ScoreIncreased(addedPoints: 42)
    ///     )
    /// )
    /// ```
    ///
    /// ```
    /// struct ScoreIncresed {
    ///     static let eventName = "ScoreIncreased"
    ///     let addedPoints: Int
    ///     // ...
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - name: A name identifying how the ``Entity`` changed
    ///   - encodableDetails: A data structure detailing the specifics of the change
    ///
    /// - Throws: If the data structure cannot be parsed as JSON (eg. if it
    ///    contains cyclic references)
    public init<T>(name: String, encodableDetails details: T) throws where T: Encodable {
        let encodedDetails = try JSONEncoder().encode(details)
        guard let details = String(data: encodedDetails, encoding: .utf8) else { throw EncodingError.notUTF8 }

        self.name = name
        self.jsonDetails = details
    }
}

enum EncodingError: Error {
    case notUTF8
}
