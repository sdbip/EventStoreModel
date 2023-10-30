import XCTest
import Source

final class DetailsTests: XCTestCase {
    func test_writesCodableDetails() throws {
        let counter = Counter(reconstitution: .init(id: "counter"))
        counter.step(count: 10)

        XCTAssertEqual(counter.unpublishedEvents.count, 1)
        XCTAssertEqual(counter.unpublishedEvents[0].jsonDetails, #"{"count":10}"#)
    }

    func test_readsDecodableDetails() throws {
        let history = History(
            id: "counter",
            type: Counter.typeId,
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

final class Counter {
    static let typeId = "Counter"
    let reconstitution: ReconstitutionData
    var unpublishedEvents: [UnpublishedEvent] = []
    var currentValue = 0

    init(reconstitution: ReconstitutionData) {
        self.reconstitution = reconstitution
    }

    func step(count: Int) {
        unpublishedEvents.append(try! UnpublishedEvent(encodableDetails: DidStepDetails(count: count)))
    }
}

extension Counter: Entity {
    func replay(_ event: PublishedEvent) {
        if event.name == "DidStep", let details = try? event.details(as: DidStepDetails.self) {
            currentValue += details.count
        }
    }
}

struct DidStepDetails: EventNaming, Codable {
    static let eventName = "DidStep"

    let count: Int
}
