import XCTest
import Source

final class TestEntity: Entity {
    static let typeId = "TestEntity"
    let unpublishedEvents: [UnpublishedEvent] = []
    var reconstitutedEvents: [PublishedEvent] = []
    var reconstitution: ReconstitutionData
    
    init(reconstitution: ReconstitutionData) {
        self.reconstitution = reconstitution
    }

    func replay(_ event: PublishedEvent) {
        reconstitutedEvents.append(event)
    }
}
