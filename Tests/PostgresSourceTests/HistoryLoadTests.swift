import XCTest

import Postgres
import PostgresClientKit

final class HistoryLoadTests: XCTestCase {
    func test_canConnect() throws {
        let connection = try Connection(configuration: configuration)
        let database = Database(connection: connection)
        let statement = try database.connection.prepareStatement(text: "SELECT 1")
        let x = try statement.execute()
            .map { try $0.get().columns[0].int() }
            .first

        XCTAssertEqual(x, 1)
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
