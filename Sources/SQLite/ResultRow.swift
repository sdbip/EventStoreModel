import SQLite3

public struct ResultRow {
    public let pointer: OpaquePointer

    init(pointer: OpaquePointer) throws {
        self.pointer = pointer
    }
}
