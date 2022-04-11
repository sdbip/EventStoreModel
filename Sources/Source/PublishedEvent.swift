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
}
