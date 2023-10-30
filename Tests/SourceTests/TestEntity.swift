import XCTest
import Source

final class TestEntity: Entity {
    static let typeId = "TestEntity"
    let unpublishedEvents: [UnpublishedEvent] = []
    var reconstitutedEvents: [PublishedEvent] = []
    var snapshotId: SnapshotId
    
    init(snapshotId: SnapshotId) {
        self.snapshotId = snapshotId
    }

    func replay(_ event: PublishedEvent) {
        reconstitutedEvents.append(event)
    }
}
