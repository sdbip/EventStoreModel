public enum EntityVersion {
    case notSaved
    case saved(Int32)

    public var next: Int32 {
        switch self {
            case .notSaved: return 0
            case .saved(let v): return v + 1
        }
    }
}

extension EntityVersion: Equatable {}
extension EntityVersion: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int32) {
        self = .saved(value)
    }
}
