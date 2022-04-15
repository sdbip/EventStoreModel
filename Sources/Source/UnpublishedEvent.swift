import Foundation

public struct UnpublishedEvent {
    public let name: String
    public let details: String

    public init(name: String, details: String) {
        self.name = name
        self.details = details
    }

    public init<T>(name: String, encodableDetails details: T) throws where T: Encodable {
        let encoder = JSONEncoder()
        let encodedDetails = try encoder.encode(details)
        self.init(name: name, details: String(data: encodedDetails, encoding: .utf8)!)
    }
}
