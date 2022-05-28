import Foundation

import Source
import SQLite

public struct EventPublisher {
    private let repository: Database

    public init(repository: Database) {
        self.repository = repository
    }

    public func publishChanges<State>(entity: Entity<State>, actor: String) throws where State: EntityState {
        try publish(events: entity.state.unpublishedEvents, entityId: entity.id, entityType: State.typeId, actor: actor) {
            v in v == entity.version.value
        }
    }

    public func publish(_ event: UnpublishedEvent, forId id: String, type: String, actor: String) throws {
        try publish(events: [event], entityId: id, entityType: type, actor: actor, isExpectedVersion: { _ in true })
    }

    private func publish(events: [UnpublishedEvent], entityId: String, entityType: String, actor: String, isExpectedVersion: (Int32?) -> Bool) throws {
        try repository.transaction {
            let currentVersion = try repository.version(ofEntityRowWithId: entityId)
            guard isExpectedVersion(currentVersion) != false else { throw SQLiteError.message("Concurrency Error") }

            if let currentVersion = currentVersion {
                try repository.setVersion(Int32(events.count) + currentVersion, onEntityRowWithId: entityId)
            } else {
                try repository.insertEntityRow(id: entityId, type: entityType, version: Int32(events.count))
            }

            var nextPosition = try repository.nextPosition()
            try repository.setNextPosition(nextPosition + Int64(events.count))

            var nextVersion = (currentVersion ?? -1) + 1
            for event in events {
                try repository.insertEventRow(
                    entityId: entityId,
                    entityType: entityType,
                    name: event.name,
                    jsonDetails: event.jsonDetails,
                    actor: actor,
                    version: nextVersion,
                    position: nextPosition)
                nextVersion += 1
                nextPosition += 1
            }
        }
    }
}
