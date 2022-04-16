import XCTest

import Source
import SQLite
import SQLiteSource

final class PublishingTests: XCTestCase {
    var publisher: EntityPublisher!

    override func setUp() {
        publisher = EntityPublisher(dbFile: testDBFile)

        do {
            try Schema.add(to: testDBFile)
        } catch {
            XCTFail("\(error)")
        }
    }

    override func tearDown() {
        do {
            try FileManager.default.removeItem(atPath: testDBFile)
        } catch { }
    }

    func test_canPublishSingleEvent() throws {
        let entity = Counter(id: "counter", version: .notSaved)
        entity.step()

        try publisher.publishChanges(entity: entity)

        _ = try Connection(openFile: testDBFile)
    }
}

final class Counter: Entity {
    static let type = "Counter"

    let id: String
    let version: EntityVersion
    var unpublishedEvents: [UnpublishedEvent] = []

    public init(id: String, version: EntityVersion) {
        self.id = id
        self.version = version
    }

    func step() {
        unpublishedEvents.append(UnpublishedEvent(name: "DidStep", details: "{}"))
    }

    func apply(_ event: PublishedEvent) {}
}
