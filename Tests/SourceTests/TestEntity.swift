import XCTest
import Source

final class TestEntity: EntityState {
    static let type = "TestEntity"
    let unpublishedEvents: [UnpublishedEvent] = []
    var lastReconstitutedEvent: PublishedEvent?

    func apply(_ event: PublishedEvent) {
        lastReconstitutedEvent = event
    }
}
