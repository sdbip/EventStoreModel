import XCTest
import Source

final class TestEntity: EntityState {
    static let typeId = "TestEntity"
    let unpublishedEvents: [UnpublishedEvent] = []
    var reconstitutedEvents: [PublishedEvent]?

    init(events: [PublishedEvent]) {
        reconstitutedEvents = events
    }
}
