import Vapor

extension Request {
    /// Gets the user object that is stored in the request by
    /// `JWTAuthenticatableMiddleware`
    func user() throws -> User {
        return try requireAuthenticated(User.self)
    }
}
