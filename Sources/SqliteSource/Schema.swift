import Foundation
import SQLite

public enum Schema {
    public static func add(to dbFile: String) throws {
        guard let schema = try bundledSchema() else { fatalError() }

        let database = try Database(openFile: dbFile)
        try database.execute(schema)
        try database.close()
    }

    private static func bundledSchema() throws -> String? {
        guard let schemaFile = Bundle.module.path(forResource: "schema", ofType: "sql") else { return nil }
        return try NSString(contentsOfFile: schemaFile, encoding: String.Encoding.utf8.rawValue) as String
    }
}
