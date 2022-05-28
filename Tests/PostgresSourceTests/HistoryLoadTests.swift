import XCTest

import PostgresClientKit

final class HistoryLoadTests: XCTestCase {
    func test_canConnect() throws {
        var config = ConnectionConfiguration()
        config.host = "localhost"
        config.port = 5432
        config.database = ProcessInfo.processInfo.environment["POSTGRES_TEST_DATABASE"] ?? ""
        config.user = ProcessInfo.processInfo.environment["POSTGRES_TEST_USER"] ?? ""
        config.ssl = false

        let connection = try Connection(configuration: config)
        let statement = try connection.prepareStatement(text: "SELECT 1")
        let x = try statement.execute()
            .map { try $0.get().columns[0].int() }
            .first
        
        XCTAssertEqual(x, 1)
    }
}
