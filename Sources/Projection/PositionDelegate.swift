public protocol PositionDelegate {
    func lastProjectedPosition() throws -> Int64?
    func update(position: Int64) throws
}
