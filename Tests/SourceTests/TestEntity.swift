import XCTest
import Source

final class TestEntity: EntityState {
    static let typeId = "TestEntity"
    let unpublishedEvents: [UnpublishedEvent] = []
    var lastReconstitutedEvent: PublishedEvent?

    func replay(_ event: PublishedEvent) {
        lastReconstitutedEvent = event
    }
}
