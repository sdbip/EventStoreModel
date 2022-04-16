import Foundation

import Source
import SQLite

public struct EntityPublisher {
    private let dbFile: String

    public init(dbFile: String) {
        self.dbFile = dbFile
    }

    public func publishChanges<EntityType>(entity: EntityType, actor: String) throws where EntityType: Entity {
        let connection = try Connection(openFile: dbFile)

        try connection.transaction {
            let statement1 = try Statement(prepare: """
                INSERT INTO Entities (id, type, version)
                VALUES (?, ?, ?);
                """,
                connection: connection)
            statement1.bind(entity.id, to: 1)
            statement1.bind(EntityType.type, to: 2)
            statement1.bind(0, to: 3)
            try statement1.execute()

            let event = entity.unpublishedEvents[0]

            let statement2 = try Statement(prepare: """
                INSERT INTO Events (entity, name, details, actor, version, position)
                VALUES (?, ?, ?, ?, ?, ?);
                """,
                connection: connection)
            statement2.bind(entity.id, to: 1)
            statement2.bind(event.name, to: 2)
            statement2.bind(event.details, to: 3)
            statement2.bind(actor, to: 4)
            statement2.bind(0, to: 5)
            statement2.bind(0, to: 6)
            try statement2.execute()
        }
    }
}
