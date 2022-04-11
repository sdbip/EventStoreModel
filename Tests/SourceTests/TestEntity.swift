import XCTest
import Source

final class TestEntity: Entity {
    static let type = "TestEntity"
    let version: EntityVersion
    var lastReconstitutedEvent: PublishedEvent?

    init(version: EntityVersion) { self.version = version }

    func apply(_ event: PublishedEvent) {
        lastReconstitutedEvent = event
    }
}
