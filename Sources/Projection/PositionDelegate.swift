public protocol PositionDelegate {
    var initialPosition: Int64? { get }
    func update(position: Int64)
}
