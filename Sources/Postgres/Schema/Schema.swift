import Foundation

public enum Schema {
    public static func add(to database: Database) throws {
        guard let schema = try bundledSchema() else { fatalError() }

        // PostgresClientKit only supports executing one statement per request.
        for sql in schema.split(separator: ";") {
            try database.operation(String(sql)).execute()
        }
    }

    private static func bundledSchema() throws -> String? {
        guard let schemaFile = Bundle.module.path(forResource: "schema", ofType: "sql") else { return nil }
        return try NSString(contentsOfFile: schemaFile, encoding: String.Encoding.utf8.rawValue) as String
    }
}

