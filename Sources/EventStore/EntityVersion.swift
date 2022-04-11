public enum EntityVersion {
    case new
    case version(Int32)

    public func get() throws -> Int32 {
        switch self {
        case .version(let version): return version
        case .new: throw ReconstitutionError.incorrectType
        }
    }
}

extension EntityVersion: Equatable {}
extension EntityVersion: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int32) {
        self = .version(value)
    }
}
