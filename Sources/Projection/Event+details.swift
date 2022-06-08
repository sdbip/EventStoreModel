import Foundation

public extension Event {
    /// Parse the JSON ``Event.details`` as a structured type that conforms to ``Decodable``.
    /// - Parameters:
    ///   - type: the structured type the details should be referenced as
    /// - Returns: The parsed data structure
    /// - Throws: If parsing fails
    func details<T>(as type: T.Type) throws -> T where T: Decodable {
        return try JSONDecoder().decode(type, from: jsonDetails.data(using: .utf8) ?? Data())
    }
}
