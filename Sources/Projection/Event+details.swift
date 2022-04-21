import Foundation

public extension Event {
    func details<T>(as type: T.Type) throws -> T where T: Decodable {
        let decoder = JSONDecoder()
        return try decoder.decode(type, from: details.data(using: .utf8)!)
    }
}
