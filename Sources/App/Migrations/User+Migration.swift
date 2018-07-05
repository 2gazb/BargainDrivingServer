import FluentMySQL
import Vapor

extension User: Migration {
    static func prepare(on connection: MySQLConnection) -> Future<Void> {
        return Database.create(self, on: connection) { creator in
            creator.field(for: \.id, isIdentifier: true)
            creator.field(for: \.username)
            creator.field(for: \.firstName)
            creator.field(for: \.lastName)
            creator.field(for: \.password)
            creator.field(for: \.permissionLevel)
            creator.field(for: \.createdAt)
            creator.field(for: \.updatedAt)
            creator.field(for: \.deletedAt)

            creator.unique(on: \.username)
        }
    }

    static func revert(on connection: MySQLConnection) -> Future<Void> {
        return Database.delete(self, on: connection)
    }
}
