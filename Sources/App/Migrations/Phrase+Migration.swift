import FluentMySQL
import Vapor

extension Phrase: Migration {
    static func prepare(on connection: MySQLConnection) -> Future<Void> {
        return Database.create(self, on: connection) { creator in
            creator.field(for: \.id, isIdentifier: true)
            creator.field(for: \.title)
            creator.field(for: \.message)
        }
    }

    static func revert(on connection: MySQLConnection) -> Future<Void> {
        return Database.delete(self, on: connection)
    }
}
