import Foundation

import Source
import SQLite

public struct EntityPublisher {
    private let dbFile: String

    public init(dbFile: String) {
        self.dbFile = dbFile
    }

    public func publishChanges(entity: Entity) throws {

    }
}
