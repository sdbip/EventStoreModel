/// The version an ``Entity`` had at the time it was reconstituted.
public enum EntityVersion {
    /// The ``Entity`` has just been created. It was not reconstituted from storage.
    case notSaved
    /// The number of events that have been published for the ``Entity``.
    case eventCount(Int32)

    /// The integer value stored in the database, or `nil` if not yet saved.
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
