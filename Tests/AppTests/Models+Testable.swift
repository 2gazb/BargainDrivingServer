@testable import App
import Crypto
import FluentMySQL

extension Phrase {
    static func create(
        title: String = "Meaningful title",
        message: String = "Useful message",
        on connection: MySQLConnection
    ) throws -> Phrase {
        let phrase = Phrase(title, message)

        return try phrase.save(on: connection).wait()
    }
}

extension User {
    static func createAdmin(
        username: String = "admin@monstarlab.jp",
        firstName: String = "Admin",
        lastName: String = "Adminovitch",
        password: String = "password",
        permissionLevel: UserStatus = .superadmin,
        on connection: MySQLConnection
    ) throws -> User {
        let user = User(username, firstName, lastName, password)

        user.password = try BCrypt.hash(user.password)
        user.permissionLevel = permissionLevel

        return try user.save(on: connection).wait()
    }

    static func createMobile(
        username: String = UUID().uuidString,
        on connection: MySQLConnection
    ) throws -> User {
        let user = User(username, nil, nil, "lylink_user")

        user.password = try BCrypt.hash(user.password)
        user.permissionLevel = .mobile

        return try user.save(on: connection).wait()
    }
}
