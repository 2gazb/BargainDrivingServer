import Fluent
import Vapor

extension User {
    struct Public: Content {
        let id: Int?
        let username: String
        let firstName: String?
        let lastName: String?
        let permissionLevel: Int

        init(user: User) {
            self.id = user.id
            self.username = user.username
            self.firstName = user.firstName
            self.lastName = user.lastName
            self.permissionLevel = user.permissionLevel.id
        }
    }

    /// Creates a `User.Public` representation of the current user
    func response(on request: Request) throws -> Future<UserResponse> {
        return Future.map(on: request) {
            return UserResponse(user: User.Public(user: self))
        }
    }
}

extension Future where T == User {
    /// Creates a `UserResponse` representation of the current user
    func userResponse(on request: Request) -> Future<UserResponse> {
        return flatMap { user in
            try user.response(on: request)
        }
    }
}

struct UserResponse: Content {
    let status = "success"
    let user: User.Public
}
