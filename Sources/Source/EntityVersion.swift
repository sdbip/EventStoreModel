public enum EntityVersion {
    case notSaved
    case eventCount(Int32)

    public var value: Int32? {
        switch self {
            case .notSaved: return nil
            case .eventCount(let count): return count
        }
    }
}

extension EntityVersion: Equatable {}
extension EntityVersion: ExpressibleByIntegerLiteral {
    public init(integerLiteral count: Int32) {
        self = .eventCount(count)
    }
}
