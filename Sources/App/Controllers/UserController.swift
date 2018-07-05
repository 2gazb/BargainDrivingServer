import Crypto
import Fluent
import JWTDataProvider
import JWTMiddleware
import Vapor

final class UserController: RouteCollection {
    func boot(router: Router) throws {
        let users = router.grouped("user")

        let loginProtected = users.grouped(JWTAuthenticatableMiddleware<User>())
        let tokenProtected = users.grouped(
            JWTAuthenticatableMiddleware<User>(),
            JWTVerificationMiddleware()
        )
        let superAdmin = users.grouped(
            PermissionsMiddleware<UserStatus, Payload>(
                allowed: [.superadmin],
                failureError: .unauthorized
            ),
            JWTVerificationMiddleware()
        )

        users.post(LoginMobileUserRequest.self, at: "mobile", "login", use: loginMobileUserHandler)
        users.post(RegisterMobileUserRequest.self, at: "mobile", "register", use: registerMobileUserHandler)
        users.post(RefreshTokenRequest.self, at: "refresh", use: refreshTokenHandler)

        loginProtected.post("admin", "login", use: loginAdminHandler)

        tokenProtected.get("status", use: statusHandler)

        superAdmin.get(use: getAllHandler)
        superAdmin.post(RegisterAdminUserRequest.self, at: "admin", "register", use: registerAdminUserHandler)
        superAdmin.patch(EditUserRequest.self, use: editHandler)
    }

    func loginMobileUserHandler(
        _ req: Request,
        _ userData: LoginMobileUserRequest
    ) throws -> Future<LoginResponse> {
        let signer = try req.make(JWTService.self)

        return User.query(on: req)
            .filter(\.username == userData.deviceToken)
            .filter(\.permissionLevel == .mobile)
            .first()
            .unwrap(or: Abort(.badRequest, reason: "The user doesn’t exist or is not a mobile user."))
            .flatMap { user in
                let userPayload = try Payload(user: user)
                let remotePayload = try req.payloadData(
                    signer.sign(userPayload),
                    with: ["userId": "\(user.requireID())"],
                    as: JSON.self
                )

                return try self.signPayload(signer, remotePayload, userPayload, user)
            }
    }

    /// POST ~/user/mobile/register
    /// Requires `deviceToken` in JSON body
    /// Adds a hard-coded password (not used for logging in anyhow, just need
    /// something to store in database and to remain compliant with JWT-related
    /// protocols)
    func registerMobileUserHandler(
        _ req: Request,
        _ userData: RegisterMobileUserRequest
    ) throws -> Future<UserResponse> {
        return try finishRegistration(req, userData.toUser())
    }

    /// POST ~/user/refresh
    /// Requires `refreshToken` in JSON body
    /// Returns refreshed access token
    func refreshTokenHandler(
        _ req: Request,
        _ refreshData: RefreshTokenRequest
    ) throws -> Future<RefreshTokenResponse> {
        let signer = try req.make(JWTService.self)
        let refreshJWT = try JWT<RefreshToken>(from: refreshData.refreshToken, verifiedUsing: signer.signer)

        try refreshJWT.payload.verify()

        let userID = refreshJWT.payload.id
        let user = User.find(userID, on: req)
            .unwrap(or: Abort(.badRequest, reason: "No user found with ID \(userID)"))

        return user.flatMap { user in
            let payload = try Payload(user: user)

            return try req
                .payloadData(
                    signer.sign(payload),
                    with: ["userId": "\(user.requireID())"],
                    as: JSON.self
                )
                .and(result: payload)
                .map { payloadData in
                    let payload = try payloadData.0.merge(payloadData.1.json())
                    let token = try signer.sign(payload)

                    return RefreshTokenResponse(accessToken: token)
                }
        }
    }

    /// POST ~/user/admin/login
    /// Requires `username` and `password` in JSON body
    /// Returns access token and refresh token
    func loginAdminHandler(_ req: Request) throws -> Future<LoginResponse> {
        let signer = try req.make(JWTService.self)
        let user = try req.requireAuthenticated(User.self)
        let userPayload = try Payload(user: user)
        let remotePayload = try req.payloadData(
            signer.sign(userPayload),
            with: ["userId": "\(user.requireID())"],
            as: JSON.self
        )

        return try signPayload(signer, remotePayload, userPayload, user)
    }

    /// GET ~/user/status
    /// Requires valid access token
    /// Returns publicly available data about currently logged in user
    func statusHandler(_ req: Request) throws -> Future<UserResponse> {
        return try req.user().response(on: req)
    }

    /// GET ~/user
    /// Returns list of all users without leaking private information
    func getAllHandler(_ req: Request) throws -> Future<AllUsersResponse> {
        return User.query(on: req).all().map { users in
            return users.map { user in
                return User.Public(user: user)
            }
        }.map(AllUsersResponse.init)
    }

    /// POST ~/user/admin/register
    /// Requires valid superadmin access token
    /// Registers additional admin account that can further be promoted to an
    /// superadmin role if needed
    func registerAdminUserHandler(
        _ req: Request,
        _ userData: RegisterAdminUserRequest
    ) throws -> Future<UserResponse> {
        let user = userData.toUser()

        try user.validate()

        return try finishRegistration(req, user)
    }

    /// PATCH ~/user
    /// Requires a valid superadmin access token
    /// Edits user’s first and last name
    func editHandler(
        _ req: Request,
        _ newData: EditUserRequest
    ) throws -> Future<UserResponse> {
        let user = try req.user()

        user.firstName = newData.firstName
        user.lastName = newData.lastName

        return user.update(on: req).userResponse(on: req)
    }

    /// Common handler for both user registration functions that actually
    /// performs the request against database and stores the user
    private func finishRegistration(_ req: Request, _ user: User) throws -> Future<UserResponse> {
        return User
            .query(on: req)
            .filter(\User.username == user.username)
            .count()
            .map(to: User.self) { count in
                guard count < 1 else {
                    throw Abort(.badRequest, reason: "This username is already registered.")
                }

                return user
            }.flatMap { user in
                user.password = try BCrypt.hash(user.password)

                return user.save(on: req).userResponse(on: req)
            }
    }

    // Common handler for both user login functions that signs the generated
    // payload and returns a proper login response
    private func signPayload(
        _ signer: JWTService,
        _ remotePayload: Future<JSON>,
        _ userPayload: Payload,
        _ user: User
    ) throws -> Future<LoginResponse> {
        return remotePayload.map { remotePayload in
            let payload = try remotePayload.merge(userPayload.json())
            let accessToken = try signer.sign(payload)
            let refreshToken = try signer.sign(RefreshToken(user: user))
            let userResponse = User.Public(user: user)

            return LoginResponse(accessToken: accessToken, refreshToken: refreshToken, user: userResponse)
        }
    }
}

struct AllUsersResponse: Content {
    let status = "success"
    let users: [User.Public]
}

struct LoginResponse: Content {
    let status = "success"
    let accessToken: String
    let refreshToken: String
    let user: User.Public
}

struct RefreshTokenRequest: Content {
    let refreshToken: String
}

struct RefreshTokenResponse: Content {
    let status = "success"
    let accessToken: String
}

struct EditUserRequest: Content {
    let firstName: String
    let lastName: String
}

struct RegisterMobileUserRequest: Content {
    let deviceToken: String

    func toUser() -> User {
        return User(deviceToken, nil, nil, "lylink_user")
    }
}

typealias LoginMobileUserRequest = RegisterMobileUserRequest

struct RegisterAdminUserRequest: Content {
    let username: String
    let firstName: String
    let lastName: String
    let password: String

    func toUser() -> User {
        let user = User(username, firstName, lastName, password)

        user.permissionLevel = .admin

        return user
    }
}
