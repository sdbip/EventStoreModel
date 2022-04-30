import Foundation

public struct UnpublishedEvent {
    public let name: String
    public let jsonDetails: String

    public init?(name: String, details: String) {
        guard let data = details.data(using: .utf8) else { return nil }
        guard let _ = try? JSONSerialization.jsonObject(with: data) else { return nil }

        self.name = name
        self.jsonDetails = details
    }

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
