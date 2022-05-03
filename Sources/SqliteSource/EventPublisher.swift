import Foundation

import Source
import SQLite

public struct EventPublisher {
    private let dbFile: String

    public init(dbFile: String) {
        self.dbFile = dbFile
    }

    public func publishChanges<State>(entity: Entity<State>, actor: String) throws where State: EntityState {
        let database = try Database(openFile: dbFile)

        let events = entity.state.unpublishedEvents

        try database.transaction {
            let currentVersion = try database.version(ofEntityWithId: entity.id)
            guard currentVersion == entity.version.value else { throw SQLiteError.message("Concurrency Error") }

            if let currentVersion = currentVersion {
                try database.updateVersion(ofEntityWithId: entity.id, to: Int32(events.count) + currentVersion)
            } else {
                try database.addEntity(id: entity.id, type: State.typeId, version: Int32(events.count))
            }

            var nextPosition = try database.nextPosition()
            try database.setPosition(nextPosition + Int64(events.count))

            var nextVersion = (currentVersion ?? -1) + 1
            for event in events {
                try database.insertEvent(entityId: entity.id, name: event.name, jsonDetails: event.jsonDetails, actor: actor, version: nextVersion, position: nextPosition)
                nextVersion += 1
                nextPosition += 1
            }
        }
    }

    public func publish(_ event: UnpublishedEvent, forId id: String, type: String, actor: String) throws {

        let database = try Database(openFile: dbFile)

        try database.transaction {
            let currentVersion = try database.version(ofEntityWithId: id)

            if let currentVersion = currentVersion {
                try database.updateVersion(ofEntityWithId: id, to: currentVersion + 1)
            } else {
                try database.addEntity(id: id, type: type, version: 1)
            }

            let nextPosition = try database.nextPosition()
            try database.setPosition(nextPosition + 1)

            let nextVersion = (currentVersion ?? -1) + 1
            try database.insertEvent(entityId: id, name: event.name, jsonDetails: event.jsonDetails, actor: actor, version: nextVersion, position: nextPosition)
        }
    }
}
