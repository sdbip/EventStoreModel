public enum EntityVersion {
    case notSaved
    case version(Int32)
}

extension EntityVersion: Equatable {}
extension EntityVersion: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int32) {
        self = .version(value)
    }
}
