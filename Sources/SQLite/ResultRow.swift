import SQLite3
import Foundation

public struct ResultRow {
    private let pointer: OpaquePointer

    init(pointer: OpaquePointer) throws {
        self.pointer = pointer
    }

    public func int32(at column: Int32) -> Int32 {
        return sqlite3_column_int(pointer, column)
    }

    public func int64(at column: Int32) -> Int64 {
        return sqlite3_column_int64(pointer, column)
    }

    public func double(at column: Int32) -> Double {
        return sqlite3_column_double(pointer, column)
    }

    public func string(at column: Int32) -> String? {
        guard let value = sqlite3_column_text(pointer, column) else { return nil }
        return String(cString: value)
    }
}
