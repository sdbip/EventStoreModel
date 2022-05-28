import XCTest

import Postgres
import PostgresClientKit
import Source

final class HistoryLoadTests: XCTestCase {
    var database: Database!

    override func setUp() async throws {
        let connection = try Connection(configuration: configuration)
        database = Database(connection: connection)
        try Schema.add(to: database)
    }

    func test_canConnect() throws {
        let operation = try database.operation("SELECT 1")

        XCTAssertEqual(try operation.single { try $0[0].int() }, 1)
    }

    func test_canUseParameters() throws {
        let operation = try database.operation("SELECT $1", parameters: 1)

        XCTAssertEqual(try operation.single { try $0[0].int() }, 1)
    }
    
    var configuration: ConnectionConfiguration {
        var config = ConnectionConfiguration()
        config.host = "localhost"
        config.port = 5432
        config.ssl = false

        if let database = ProcessInfo.processInfo.environment["POSTGRES_TEST_DATABASE"] {
            config.database = database
        }

        if let user = ProcessInfo.processInfo.environment["POSTGRES_TEST_USER"] {
            config.user = user
        }

        if let password = ProcessInfo.processInfo.environment["POSTGRES_TEST_PASS"] {
            config.credential = Credential.cleartextPassword(password: password)
        }

        return config
    }
}
