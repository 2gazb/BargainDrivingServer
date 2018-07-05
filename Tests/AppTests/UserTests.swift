@testable import App
import FluentMySQL
import JWTDataProvider
import JWTMiddleware
import Vapor
import XCTest

final class UserTests: XCTestCase {
    let userURI = "/api/v1/user"
    let userMobileUsername = "50098046-60e6-4cc6-9511-5ca315b64bea"
    let userAdminUsername = "user@monstarlab.jp"
    let userFirstName = "Monstar"
    let userLastName = "Lab"
    let userPassword = "password"

    var app: Application!
    var conn: MySQLConnection!

    override func setUp() {
        try! Application.reset()

        app = try! Application.testable()
        conn = try! app.newConnection(to: .mysql).wait()
    }

    override func tearDown() {
        conn.close()
    }

    func testLoginMobileUser__createsAccessToken() throws {
        let mobileUser = try User.createMobile(on: conn)
        let endpoint = "\(userURI)/mobile/login"
        let response = try app.getResponse(
            to: endpoint,
            method: .POST,
            body: MobileLoginRequest(deviceToken: mobileUser.username),
            decodeTo: LoginResponse.self
        )

        XCTAssertEqual(response.status, "success")
        XCTAssertEqual(response.user.username, mobileUser.username)
        XCTAssertNil(response.user.firstName)
        XCTAssertNil(response.user.lastName)
        XCTAssertEqual(response.user.permissionLevel, 2)
        XCTAssertEqual(response.accessToken.components(separatedBy: ".").count, 3)
        XCTAssertEqual(response.refreshToken.components(separatedBy: ".").count, 3)
    }

    func testLoginMobileUser__onlyLogsInMobileUsers() throws {
        let mobileUser = try User.createMobile(on: conn)
        let adminUser = try User.createAdmin(
            username: userAdminUsername,
            firstName: userFirstName,
            lastName: userLastName,
            password: userPassword,
            permissionLevel: .admin,
            on: conn
        )
        let superadminUser = try User.createAdmin(on: conn)
        let endpoint = "\(userURI)/mobile/login"
        let mobileResponse = try app.sendRequest(
            to: endpoint,
            method: .POST,
            body: MobileLoginRequest(deviceToken: mobileUser.username)
        )
        let adminResponse = try app.sendRequest(
            to: endpoint,
            method: .POST,
            body: MobileLoginRequest(deviceToken: adminUser.username)
        )
        let superadminResponse = try app.sendRequest(
            to: endpoint,
            method: .POST,
            body: MobileLoginRequest(deviceToken: superadminUser.username)
        )

        XCTAssertEqual(mobileResponse.http.status.code, 200)
        XCTAssertEqual(adminResponse.http.status.code, 400)
        XCTAssertEqual(superadminResponse.http.status.code, 400)
    }

    func testRegisterMobileUser__createsMobileuser() throws {
        let userToCreate = RegisterMobileUserRequest(deviceToken: userMobileUsername)
        let endpoint = "\(userURI)/mobile/register"
        let createdUser = try app.getResponse(
            to: endpoint,
            method: .POST,
            body: userToCreate,
            decodeTo: UserResponse.self
        )

        XCTAssertEqual(createdUser.status, "success")
        XCTAssertEqual(createdUser.user.username, userMobileUsername)
        XCTAssertNil(createdUser.user.firstName)
        XCTAssertNil(createdUser.user.lastName)
        XCTAssertEqual(createdUser.user.permissionLevel, 2)
    }

    func testRefreshToken__increasesExpiration() throws {
        let superadminUser = try User.createAdmin(on: conn)
        let tokens = try app.getResponse(
            to: "\(userURI)/admin/login",
            method: .POST,
            body: AdminLoginRequest(username: superadminUser.username, password: "password"),
            decodeTo: LoginResponse.self
        )
        let signer = try app.make(JWTService.self)
        let newToken = try app.getResponse(
            to: "\(userURI)/refresh",
            method: .POST,
            body: RefreshTokenRequest(refreshToken: tokens.refreshToken),
            decodeTo: RefreshTokenResponse.self
        )
        let oldAccessJWT = try JWT<Payload>(
            from: tokens.accessToken,
            verifiedUsing: signer.signer
        )
        let newAccessJWT = try JWT<Payload>(
            from: newToken.accessToken,
            verifiedUsing: signer.signer
        )

        XCTAssertGreaterThan(newAccessJWT.payload.exp, oldAccessJWT.payload.exp)
    }

    func testLoginAdminUser__createsAccessToken() throws {
        let superadminUser = try User.createAdmin(on: conn)
        let endpoint = "\(userURI)/admin/login"
        let response = try app.getResponse(
            to: endpoint,
            method: .POST,
            body: AdminLoginRequest(username: superadminUser.username, password: "password"),
            decodeTo: LoginResponse.self
        )

        XCTAssertEqual(response.status, "success")
        XCTAssertEqual(response.user.username, superadminUser.username)
        XCTAssertEqual(response.user.firstName, superadminUser.firstName)
        XCTAssertEqual(response.user.lastName, superadminUser.lastName)
        XCTAssertEqual(response.user.permissionLevel, 0)
        XCTAssertEqual(response.accessToken.components(separatedBy: ".").count, 3)
        XCTAssertEqual(response.refreshToken.components(separatedBy: ".").count, 3)
    }

    func testListUsers__hasCorrectPrivileges() throws {
        let mobileUser = try User.createMobile(username: userMobileUsername, on: conn)
        let superadminUser = try User.createAdmin(on: conn)
        let loggedOut = try app.sendRequest(to: userURI, method: .GET)
        let loggedIn = try app.sendRequest(
            to: userURI,
            method: .GET,
            loggedInUser: mobileUser,
            mobileUser: true
        )
        let loggedInSuperadmin = try app.sendRequest(
            to: userURI,
            method: .GET,
            loggedInUser: superadminUser
        )

        XCTAssertEqual(loggedOut.http.status.code, 401)
        XCTAssertEqual(loggedIn.http.status.code, 401)
        XCTAssertEqual(loggedInSuperadmin.http.status.code, 200)
    }

    func testListUsers__retrievesUsers() throws {
        let superadminUser = try User.createAdmin(
            username: userAdminUsername,
            firstName: userFirstName,
            lastName: userLastName,
            password: "password",
            on: conn
        )
        let _ = try User.createMobile(on: conn)
        let users = try app.getResponse(
            to: userURI,
            method: .GET,
            decodeTo: AllUsersResponse.self,
            loggedInUser: superadminUser
        )

        XCTAssertEqual(users.status, "success")
        XCTAssertEqual(users.users.count, 2)
        XCTAssertEqual(users.users[0].username, userAdminUsername)
        XCTAssertEqual(users.users[0].firstName, userFirstName)
        XCTAssertEqual(users.users[0].lastName, userLastName)
    }

    func testRegisterAdminUser__hasCorrectPrivileges() throws {
        let mobileUser = try User.createMobile(on: conn)
        let superadminUser = try User.createAdmin(on: conn)
        let userToCreate = User("new@monstarlab.jp", "New", "User", "password")
        let endpoint = "\(userURI)/admin/register"
        let loggedOut = try app.sendRequest(to: endpoint, method: .POST, body: userToCreate)
        let loggedIn = try app.sendRequest(
            to: endpoint,
            method: .POST,
            body: userToCreate,
            loggedInUser: mobileUser,
            mobileUser: true
        )
        let loggedInSuperadmin = try app.sendRequest(
            to: endpoint,
            method: .POST,
            body: userToCreate,
            loggedInUser: superadminUser
        )

        XCTAssertEqual(loggedOut.http.status.code, 401)
        XCTAssertEqual(loggedIn.http.status.code, 401)
        XCTAssertEqual(loggedInSuperadmin.http.status.code, 200)
    }

    func testRegisterAdminUser__createsAdminUser() throws {
        let superadminUser = try User.createAdmin(on: conn)
        let userToCreate = RegisterAdminUserRequest(
            username: userAdminUsername,
            firstName: userFirstName,
            lastName: userLastName,
            password: userPassword
        )
        let endpoint = "\(userURI)/admin/register"
        let createdUser = try app.getResponse(
            to: endpoint,
            method: .POST,
            body: userToCreate,
            decodeTo: UserResponse.self,
            loggedInUser: superadminUser
        )

        XCTAssertEqual(createdUser.status, "success")
        XCTAssertEqual(createdUser.user.username, userAdminUsername)
        XCTAssertEqual(createdUser.user.firstName, userFirstName)
        XCTAssertEqual(createdUser.user.lastName, userLastName)
        XCTAssertEqual(createdUser.user.permissionLevel, 1) // UserStatus.admin
    }
}
