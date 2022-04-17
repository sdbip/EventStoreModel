import SQLite3

private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

public protocol Bindable {
	func statusCode(bindingTo operation: OpaquePointer, at index: Int32) -> Int32
}

extension String: Bindable {
	public func statusCode(bindingTo pointer: OpaquePointer, at index: Int32) -> Int32 {
        sqlite3_bind_text(pointer, index, self, -1, SQLITE_TRANSIENT)
    }
}

extension Int32: Bindable {
	public func statusCode(bindingTo pointer: OpaquePointer, at index: Int32) -> Int32 {
        sqlite3_bind_int(pointer, index, self)
    }
}

extension Int64: Bindable {
	public func statusCode(bindingTo pointer: OpaquePointer, at index: Int32) -> Int32 {
        sqlite3_bind_int64(pointer, index, self)
    }
}
