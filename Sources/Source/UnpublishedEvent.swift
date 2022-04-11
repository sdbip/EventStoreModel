import Foundation

public struct UnpublishedEvent {
    public let name: String
    public let details: String

    public init(name: String, details: String) {
        self.name = name
        self.details = details
    }
}
