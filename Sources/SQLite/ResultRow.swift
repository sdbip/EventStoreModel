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

    public func date(at column: Int32) -> Date {
        let julianDay = double(at: column)
        let timeInterval = (julianDay - julianDayAtReferenceDate) * secondsPerDay
        return Date(timeIntervalSinceReferenceDate: timeInterval)
    }
}

// Swift reference date is January 1, 2001 CE @ 0:00:00
// Julian Day 0 is November 24, 4714 BCE @ 12:00:00
// Those dates are 2451910.5 days apart.
private let julianDayAtReferenceDate = 2451910.5
private let secondsPerDay = 86_400 as Double
