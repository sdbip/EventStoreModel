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
            try connection.add(entity)

            for event in entity.unpublishedEvents {
                try connection.publish(event, entityId: entity.id, actor: actor)
            }
        }
    }
}

private extension Connection {
    func add<EntityType>(_ entity: EntityType) throws where EntityType: Entity {
        let statement = try Statement(prepare: """
            INSERT INTO Entities (id, type, version)
            VALUES (?, ?, ?);
            """,
            connection: self)
        statement.bind(entity.id, to: 1)
        statement.bind(EntityType.type, to: 2)
        statement.bind(0, to: 3)
        try statement.execute()
    }

    func publish(_ event: UnpublishedEvent, entityId: String, actor: String) throws {
        let statement = try Statement(prepare: """
            INSERT INTO Events (entity, name, details, actor, version, position)
            VALUES (?, ?, ?, ?, ?, ?);
            """,
            connection: self)
        statement.bind(entityId, to: 1)
        statement.bind(event.name, to: 2)
        statement.bind(event.details, to: 3)
        statement.bind(actor, to: 4)
        statement.bind(0, to: 5)
        statement.bind(0, to: 6)
        try statement.execute()
    }
}
