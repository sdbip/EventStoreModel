public enum EntityVersion {
    case notSaved
    case eventCount(Int32)

    public var next: Int32 {
        switch self {
            case .notSaved: return 0
            case .eventCount(let count): return count + 1
        }
    }
}

extension EntityVersion: Equatable {}
extension EntityVersion: ExpressibleByIntegerLiteral {
    public init(integerLiteral count: Int32) {
        self = .eventCount(count)
    }
}
