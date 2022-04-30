import Foundation

public extension Event {
    func details<T>(as type: T.Type) throws -> T where T: Decodable {
        return try JSONDecoder().decode(type, from: jsonDetails.data(using: .utf8)!)
    }
}
