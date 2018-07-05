// Generated using Sourcery 0.13.1 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

import XCTest
@testable import AppTests

extension PhraseTests {
    static var allTests = [
        ("testListPhrases___retrievesPhrases", testListPhrases___retrievesPhrases),
        ("testGetPhrase__retrievesPhrase", testGetPhrase__retrievesPhrase),
        ("testSavePhrase__savesPhrase", testSavePhrase__savesPhrase),
        ("testUpdatePhrase__updatesPhrase", testUpdatePhrase__updatesPhrase)
    ]
}

extension UserTests {
    static var allTests = [
        ("testLoginMobileUser__createsAccessToken", testLoginMobileUser__createsAccessToken),
        ("testLoginMobileUser__onlyLogsInMobileUsers", testLoginMobileUser__onlyLogsInMobileUsers),
        ("testRegisterMobileUser__createsMobileuser", testRegisterMobileUser__createsMobileuser),
        ("testRefreshToken__increasesExpiration", testRefreshToken__increasesExpiration),
        ("testLoginAdminUser__createsAccessToken", testLoginAdminUser__createsAccessToken),
        ("testListUsers__hasCorrectPrivileges", testListUsers__hasCorrectPrivileges),
        ("testListUsers__retrievesUsers", testListUsers__retrievesUsers),
        ("testRegisterAdminUser__hasCorrectPrivileges", testRegisterAdminUser__hasCorrectPrivileges),
        ("testRegisterAdminUser__createsAdminUser", testRegisterAdminUser__createsAdminUser)
    ]
}

XCTMain([
    testCase(PhraseTests.allTests),
    testCase(UserTests.allTests)
])
