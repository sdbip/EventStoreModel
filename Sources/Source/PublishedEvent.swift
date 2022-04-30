import Foundation

public struct PublishedEvent {
    public let name: String
    public let jsonDetails: String
    public let actor: String
    public let timestamp: Date

    public init(name: String, details: String, actor: String, timestamp: Date) {
        self.name = name
        self.jsonDetails = details
        self.actor = actor
        self.timestamp = timestamp
    }

    public func details<T>(as type: T.Type) throws -> T where T: Decodable {
        return try JSONDecoder().decode(T.self, from: jsonDetails.data(using: .utf8)!)
    }
}
