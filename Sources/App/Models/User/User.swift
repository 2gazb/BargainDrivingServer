import Crypto
import FluentMySQL
import SkelpoMiddleware
import Validation
import Vapor

final class User: Content {
    /// Database ID
    var id: Int?

    /// Username: e-mail for admins, but a random device token for mobile users
    var username: String

    /// User’s first name
    var firstName: String?

    /// User’s last name
    var lastName: String?

    /// User’s hashed password
    var password: String

    /// User’s permission level; the higher the… better?
    var permissionLevel: UserStatus

    /// Date when the user account was created
    var createdAt: Date?

    /// Date when the user account was last updated
    var updatedAt: Date?

    /// Date when the user account was deactivated
    var deletedAt: Date?

    /// New way of marking model as `Timestampable` and `SoftDeletable`
    static var createdAtKey: TimestampKey? { return \.createdAt }
    static var updatedAtKey: TimestampKey? { return \.updatedAt }
    static var deletedAtKey: TimestampKey? { return \.deletedAt }

    init(
        _ username: String,
        _ firstName: String? = nil,
        _ lastName: String? = nil,
        _ password: String
    ) {
        self.username = username
        self.firstName = firstName
        self.lastName = lastName
        self.password = password
        self.permissionLevel = .mobile
    }
}

extension User: MySQLModel {}
extension User: Parameter {}

extension User: Validatable {
    static func validations() throws -> Validations<User> {
        var validations = Validations(User.self)

        try validations.add(\.password, .ascii && .count(8...))

        return validations
    }
}

/// This allows the verification of the `User` model with
/// `JWTAuthenticatableMiddleware`
extension User: BasicJWTAuthenticatable {
    /// The key-path for the property to check against `AuthBody.username`
    /// when fetching the user from the database to authenticate.
    static var usernameKey: KeyPath<User, String> {
        return \.username
    }

    /// Creates an access token that is used to verify future requests
    func accessToken(on request: Request) throws -> Future<Payload> {
        return Future.map(on: request) {
            try Payload(user: self)
        }
    }
}
