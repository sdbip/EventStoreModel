import SQLite3
import XCTest

import Projection
import SQLiteProjection
import SQLite

private let testDbFile = "test.db"

final class SQLiteEventRepositoryTests: XCTestCase {
    var repository: SQLiteEventRepository!

    override func setUp() {
        do {
            try FileManager.default.removeItem(atPath: testDbFile)
        } catch {
            // do nothing
        }

        do {
            try Schema.add(to: testDbFile)
            let connection = try Database(openFile: testDbFile)
            try connection.execute("""
                INSERT INTO Entities (id, type, version)
                    VALUES ('entity', 'type', 0);
                """)
        } catch {
            // ignore
        }

        repository = SQLiteEventRepository(file: testDbFile)
    }

    func test_readEventsAt_returnsEvents() throws {
        let connection = try Database(openFile: testDbFile)
        try connection.execute("""
            INSERT INTO Events (entity, name, details, actor, version, position)
                VALUES ('entity', 'name', '{}', 'actor', 1, 1)
            """)

        let events = try repository.readEvents(at: 1)

        XCTAssertEqual(events,
            [Event(
                entityId: "entity",
                name: "name",
                entityType: "type",
                details: "{}",
                position: 1
            )])
    }

    func test_readEventsAt_returnsOnlyEventsAtTheIndicatedPosition() throws {
        let connection = try Database(openFile: testDbFile)
        try connection.execute("""
            INSERT INTO Events (entity, name, details, actor, version, position) VALUES
                ('entity', 'name', '{}', 'actor', 0, 0),
                ('entity', 'name', '{}', 'actor', 1, 1),
                ('entity', 'name', '{}', 'actor', 2, 2)
            """)

        let events = try repository.readEvents(at: 1)

        XCTAssert(events.allSatisfy({ $0.position == 1 }))

    }

    func test_readEventsAfter_returnsEvents() throws {
        let connection = try Database(openFile: testDbFile)
        try connection.execute("""
            INSERT INTO Events (entity, name, details, actor, version, position)
                VALUES ('entity', 'name', '{}', 'actor', 1, 1)
            """)

        let events = try repository.readEvents(maxCount: 1, after: 0)

        XCTAssertEqual(events,
            [Event(
                entityId: "entity",
                name: "name",
                entityType: "type",
                details: "{}",
                position: 1
            )])
    }

    func test_readEventsAfter_returnsOnlyEventsAtLaterPositions() throws {
        let connection = try Database(openFile: testDbFile)
        try connection.execute("""
            INSERT INTO Events (entity, name, details, actor, version, position) VALUES
                ('entity', 'name', '{}', 'actor', 0, 0),
                ('entity', 'name', '{}', 'actor', 1, 1),
                ('entity', 'name', '{}', 'actor', 2, 2)
            """)

        let events = try repository.readEvents(maxCount: 3, after: 0)

        XCTAssertEqual(events.map { $0.position }, [1, 2])
    }
    
    func test_readEventsAfter_returnsAllEventsWhenNoPositionSpecified() throws {
        let connection = try Database(openFile: testDbFile)
        try connection.execute("""
            INSERT INTO Events (entity, name, details, actor, version, position) VALUES
                ('entity', 'name', '{}', 'actor', 0, 0),
                ('entity', 'name', '{}', 'actor', 1, 1),
                ('entity', 'name', '{}', 'actor', 2, 2)
            """)

        let events = try repository.readEvents(maxCount: 3, after: nil)

        XCTAssertEqual(events.map { $0.position }, [0, 1, 2])
    }
    
    func test_readEventsFromBeginning_returnsNoMoreThanMaxCountEvents() throws {
        let connection = try Database(openFile: testDbFile)
        try connection.execute("""
            INSERT INTO Events (entity, name, details, actor, version, position) VALUES
                ('entity', 'name', '{}', 'actor', 0, 0),
                ('entity', 'name', '{}', 'actor', 1, 1),
                ('entity', 'name', '{}', 'actor', 2, 2)
            """)

        let events = try repository.readEvents(maxCount: 2, after: nil)

        XCTAssertEqual(events.map { $0.position }, [0, 1])
    }
    
    func test_readEventsAfter_returnsNoMoreThanMaxCountEvents() throws {
        let connection = try Database(openFile: testDbFile)
        try connection.execute("""
            INSERT INTO Events (entity, name, details, actor, version, position) VALUES
                ('entity', 'name', '{}', 'actor', 0, 0),
                ('entity', 'name', '{}', 'actor', 1, 1),
                ('entity', 'name', '{}', 'actor', 2, 2)
            """)

        let events = try repository.readEvents(maxCount: 1, after: 0)

        XCTAssertEqual(events.map { $0.position }, [1])
    }
}

extension Event: Equatable {
    public static func ==(left: Event, right: Event) -> Bool {
        return left.entityId == right.entityId &&
        left.entityType == right.entityType &&
        left.name == right.name &&
        left.jsonDetails == right.jsonDetails &&
        left.position == right.position
    }
}
