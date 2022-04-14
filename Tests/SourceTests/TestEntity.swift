import XCTest
import Source

final class TestEntity: Entity {
    static let type = "TestEntity"
    let id: String
    let version: EntityVersion
    let unpublishedEvents: [UnpublishedEvent]
    var lastReconstitutedEvent: PublishedEvent?

    init(id: String, version: EntityVersion) {
        self.id = id
        self.version = version
        unpublishedEvents = []
    }

    func apply(_ event: PublishedEvent) {
        lastReconstitutedEvent = event
    }
}
