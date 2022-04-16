public enum EntityVersion {
    case notSaved
    case version(Int32)

    public var next: Int32 {
        switch self {
            case .notSaved: return 0
            case .version(let v): return v + 1
        }
    }
}

extension EntityVersion: Equatable {}
extension EntityVersion: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int32) {
        self = .version(value)
    }
}
