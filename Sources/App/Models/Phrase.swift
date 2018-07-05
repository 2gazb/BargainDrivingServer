import FluentMySQL
import Vapor

final class Phrase: Codable {
    var id: Int?
    var title: String
    var message: String

    init(_ title: String, _ message: String) {
        self.title = title
        self.message = message
    }
}

extension Phrase: MySQLModel {}
extension Phrase: Content {}
extension Phrase: Parameter {}
