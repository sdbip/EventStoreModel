import Foundation

public enum Schema {
    public static func add(to dbFile: String) throws {
        let database = try Database(openFile: dbFile)
        try add(to: database)
        try database.close()
    }

    public static func add(to database: Database) throws {
        guard let schema = try bundledSchema() else { fatalError() }

        try database.execute(schema)
    }

    private static func bundledSchema() throws -> String? {
        guard let schemaFile = Bundle.module.path(forResource: "schema", ofType: "sql") else { return nil }
        return try NSString(contentsOfFile: schemaFile, encoding: String.Encoding.utf8.rawValue) as String
    }
}
