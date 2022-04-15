import Foundation

public struct PublishedEvent {
    public let name: String
    public let details: String
    public let actor: String
    public let timestamp: Date

    public init(name: String, details: String, actor: String, timestamp: Date) {
        self.name = name
        self.details = details
        self.actor = actor
        self.timestamp = timestamp
    }

    public func details<T>(as type: T.Type) throws -> T? where T: Decodable {
        guard let data = details.data(using: .utf8) else { return nil }
        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: data)
    }
}
