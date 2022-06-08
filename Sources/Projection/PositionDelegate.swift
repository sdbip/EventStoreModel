/// Protocol for remembering the last ``Event`` that was processed, if the
/// state of the ``EventSource`` is lost.
///
/// Implement ``update(position:)`` to (repeatedly) persist the` position` of
/// the last processed ``Event``. Then return that value (maybe after restarting
/// the application) from ``lastProjectedPosition()``-
public protocol PositionDelegate {
    /// The position that was last sent to the ``update(position:)`` method..
    ///
    /// When starting projection from nothing, return `nil` here.
    func lastProjectedPosition() throws -> Int64?
    /// Indicates that an ``Event`` finished processing and, if it should not
    /// be processed again, this number should be returned by
    /// ``lastProjectedPosition()``.if the ``EventSource``
    /// has to be recreated.
    ///
    /// - Parameters:
    ///   - position: A number that uniquely identifies the ``Event``.
    func update(position: Int64) throws
}
