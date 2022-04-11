import XCTest
import EventStore

final class ReconstitutionTests: XCTestCase {
    func test_() throws {
        let entity: TestEntity = reconstitute()

        XCTAssertNotNil(entity)
    }
}

func reconstitute<T: Entity>() -> T {
    return T()
}

final class TestEntity: Entity {

}
