import XCTest
import Source

final class TestEntity: Entity {
    static let type = "TestEntity"
    let version: EntityVersion
    let unpublishedEvents: [UnpublishedEvent]
    var lastReconstitutedEvent: PublishedEvent?

    init(version: EntityVersion) {
        self.version = version
        unpublishedEvents = []
    }

    func apply(_ event: PublishedEvent) {
        lastReconstitutedEvent = event
    }
}
