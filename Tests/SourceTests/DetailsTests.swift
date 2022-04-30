import XCTest
import Source

final class DetailsTests: XCTestCase {
    func test_writesCodableDetails() throws {
        let counter = Counter(id: "counter", version: .notSaved)
        counter.step(count: 10)

        XCTAssertEqual(counter.unpublishedEvents.count, 1)
        XCTAssertEqual(counter.unpublishedEvents[0].jsonDetails, #"{"count":10}"#)
    }

    func test_readsDecodableDetails() throws {
        let history = History(
            id: "counter",
            type: Counter.type,
            events: [
                PublishedEvent(
                    name: "DidStep",
                    details: #"{"count":10}"#,
                    actor: "whomever",
                    timestamp: Date()
                )
            ],
            version: 0)

        let counter: Counter = try history.entity()
        XCTAssertEqual(counter.currentValue, 10)
    }
}

final class Counter: Entity {
    static let type = "Counter"
    let id: String
    let version: EntityVersion
    var unpublishedEvents: [UnpublishedEvent] = []
    var currentValue = 0

    init(id: String, version: EntityVersion) {
        self.id = id
        self.version = version
    }

    func step(count: Int) {
        unpublishedEvents.append(try! UnpublishedEvent(name: "DidStep", encodableDetails: DidStepDetails(count: count)))
    }

    func apply(_ event: PublishedEvent) {
        if event.name == "DidStep", let details = try? event.details(as: DidStepDetails.self) {
            currentValue += details.count
        }
    }
}

struct DidStepDetails: Codable {
    let count: Int
}
