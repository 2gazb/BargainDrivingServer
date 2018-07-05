@testable import App
import FluentMySQL
import Vapor

extension Application {
    static func testable(envArgs: [String]? = nil) throws -> Application {
        var config = Config.default()
        var env = Environment.testing
        var services = Services.default()

        if let envArgs = envArgs {
            env.arguments = envArgs
        }

        try App.configure(&config, &env, &services)

        let app = try Application(config: config, environment: env, services: services)

        try App.boot(app)

        return app
    }

    static func reset() throws {
        let revertEnvironment = ["vapor", "revert", "--all", "-y"]

        try Application.testable(envArgs: revertEnvironment).asyncRun().wait()
    }

    @discardableResult
    func sendRequest<T>(
        to path: String,
        method: HTTPMethod,
        headers: HTTPHeaders = .init(),
        body: T? = nil,
        loggedInUser: User? = nil,
        mobileUser: Bool = false
    ) throws -> Response where T: Content {
        var headers = headers

        if let user = loggedInUser {
            let token: LoginResponse

            if mobileUser {
                let loginRequest = MobileLoginRequest(deviceToken: user.username)

                token = try getResponse(to: "/api/v1/user/mobile/login", method: .POST, body: loginRequest, decodeTo: LoginResponse.self)
            } else {
                let loginRequest = AdminLoginRequest(username: user.username, password: "password")

                token = try getResponse(to: "/api/v1/user/admin/login", method: .POST, body: loginRequest, decodeTo: LoginResponse.self)
            }

            headers.add(name: .authorization, value: "Bearer \(token.accessToken)")
        }

        let responder = try make(Responder.self)
        let request = HTTPRequest(method: method, url: URL(string: path)!, headers: headers)
        let wrappedRequest = Request(http: request, using: self)

        if let body = body {
            try wrappedRequest.content.encode(body)
        }

        return try responder.respond(to: wrappedRequest).wait()
    }

    @discardableResult
    func sendRequest(
        to path: String,
        method: HTTPMethod,
        headers: HTTPHeaders = .init(),
        loggedInUser: User? = nil,
        mobileUser: Bool = false
    ) throws -> Response {
        let emptyContent: EmptyContent? = nil

        return try sendRequest(
            to: path,
            method: method,
            headers: headers,
            body: emptyContent,
            loggedInUser: loggedInUser,
            mobileUser: mobileUser
        )
    }

    @discardableResult
    func getResponse<C, T>(
        to path: String,
        method: HTTPMethod = .GET,
        headers: HTTPHeaders = .init(),
        body: C? = nil,
        decodeTo type: T.Type,
        loggedInUser: User? = nil,
        mobileUser: Bool = false
    ) throws -> T where C: Content, T: Decodable {
        let response = try sendRequest(
            to: path,
            method: method,
            headers: headers,
            body: body,
            loggedInUser: loggedInUser,
            mobileUser: mobileUser
        )

        return try response.content.decode(type).wait()
    }

    @discardableResult
    func getResponse<T>(
        to path: String,
        method: HTTPMethod = .GET,
        headers: HTTPHeaders = .init(),
        decodeTo type: T.Type,
        loggedInUser: User? = nil,
        mobileUser: Bool = false
    ) throws -> T where T: Content {
        let emptyContent: EmptyContent? = nil

        return try getResponse(
            to: path,
            method: method,
            headers: headers,
            body: emptyContent,
            decodeTo: type,
            loggedInUser: loggedInUser,
            mobileUser: mobileUser
        )
    }
}

struct EmptyContent: Content {}

struct AdminLoginRequest: Content {
    let username: String
    let password: String
}

struct MobileLoginRequest: Content {
    let deviceToken: String
}
