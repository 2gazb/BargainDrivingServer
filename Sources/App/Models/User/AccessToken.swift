import Crypto
import Foundation
import JSON
import JWT
import SkelpoMiddleware
import Vapor

/// A representation of the payload used in the access tokens for this
/// service’s authentication
struct Payload: PermissionedUserPayload {
    let id: User.ID
    let username: String
    let firstName: String?
    let lastName: String?
    let status: UserStatus
    let exp: TimeInterval
    let iat: TimeInterval

    init(user: User, expiration: TimeInterval = 60 * 60) throws {
        let now = Date().timeIntervalSince1970

        self.id = try user.requireID()
        self.username = user.username
        self.firstName = user.firstName
        self.lastName = user.lastName
        self.status = user.permissionLevel
        self.exp = now + expiration
        self.iat = now
    }

    func verify() throws {
        let expiration = Date(timeIntervalSince1970: exp)

        try ExpirationClaim(value: expiration).verify()
    }
}

/// Payload data for a refresh token
struct RefreshToken: IdentifiableJWTPayload {
    let id: User.ID
    let exp: TimeInterval
    let iat: TimeInterval

    init(user: User, expiration: TimeInterval = 24 * 60 * 60 * 30) throws {
        let now = Date().timeIntervalSince1970

        self.id = try user.requireID()
        self.exp = now + expiration
        self.iat = now
    }

    func verify() throws {
        let expiration = Date(timeIntervalSince1970: exp)

        try ExpirationClaim(value: expiration).verify()
    }
}

extension JSON: JWTPayload {
    public func verify() throws {
        // Don't do anything
        // We only conform to `JWTPayload` so we can sign a JWT with JSON as
        // its payload.
    }
}
