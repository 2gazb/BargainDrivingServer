@testable import App
import FluentMySQL
import Vapor
import XCTest

final class PhraseTests: XCTestCase {
    let phraseURI = "/api/v1/phrase"
    let phraseTitle = "Here's a title"
    let phraseMessage = "And here's a message"
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

    func testListPhrases___retrievesPhrases() throws {
        let phrase1 = try Phrase.create(title: phraseTitle, message: phraseMessage, on: conn)
        _ = try Phrase.create(on: conn)

        let phrases = try app.getResponse(to: phraseURI, decodeTo: [Phrase].self)

        XCTAssertEqual(phrases.count, 2)
        XCTAssertEqual(phrases[0].id, phrase1.id)
        XCTAssertEqual(phrases[0].title, phraseTitle)
        XCTAssertEqual(phrases[0].message, phraseMessage)
    }

    func testGetPhrase__retrievesPhrase() throws {
        let phrase = try Phrase.create(title: phraseTitle, message: phraseMessage, on: conn)
        let endpoint = "\(phraseURI)/\(phrase.id!)"
        let returnedPhrase = try app.getResponse(to: endpoint, decodeTo: Phrase.self)

        XCTAssertEqual(returnedPhrase.id, phrase.id)
        XCTAssertEqual(returnedPhrase.title, phraseTitle)
        XCTAssertEqual(returnedPhrase.message, phraseMessage)
    }

    func testSavePhrase__savesPhrase() throws {
        let phrase = Phrase(phraseTitle, phraseMessage)
        let receivedPhrase = try app.getResponse(
            to: phraseURI,
            method: .POST,
            headers: ["Content-Type": "application/json"],
            body: phrase,
            decodeTo: Phrase.self
        )

        XCTAssertEqual(receivedPhrase.title, phraseTitle)
        XCTAssertEqual(receivedPhrase.message, phraseMessage)
        XCTAssertNotNil(receivedPhrase.id)

        let phrases = try app.getResponse(to: phraseURI, decodeTo: [Phrase].self)

        XCTAssertEqual(phrases.count, 1)
        XCTAssertEqual(phrases[0].id, receivedPhrase.id)
        XCTAssertEqual(phrases[0].title, phraseTitle)
        XCTAssertEqual(phrases[0].message, phraseMessage)
    }

    func testUpdatePhrase__updatesPhrase() throws {
        let phrase = try Phrase.create(title: phraseTitle, message: phraseMessage, on: conn)
        let endpoint = "\(phraseURI)/\(phrase.id!)"
        let newMessage = "Now with a whole lot more stability"
        let updatedAcronym = Phrase(phraseTitle, newMessage)

        try app.sendRequest(
            to: endpoint,
            method: .PUT,
            headers: ["Content-Type": "application/json"],
            body: updatedAcronym
        )

        let returnedPhrase = try app.getResponse(to: endpoint, decodeTo: Phrase.self)

        XCTAssertEqual(returnedPhrase.title, returnedPhrase.title)
        XCTAssertEqual(returnedPhrase.message, returnedPhrase.message)
    }
}
