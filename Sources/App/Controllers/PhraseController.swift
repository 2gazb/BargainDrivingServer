import Fluent
import Vapor

struct PhraseController: RouteCollection {
    func boot(router: Router) throws {
        let phraseRoutes = router.grouped("phrase")

        phraseRoutes.get(use: getAllHandler)
        phraseRoutes.get(Phrase.parameter, use: getHandler)
        phraseRoutes.post(Phrase.self, use: createHandler)
        phraseRoutes.put(Phrase.parameter, use: updateHandler)
    }

    func getAllHandler(_ req: Request) -> Future<[Phrase]> {
        return Phrase.query(on: req).all()
    }

    func getHandler(_ req: Request) throws -> Future<Phrase> {
        return try req.parameters.next(Phrase.self)
    }

    func createHandler(_ req: Request, phrase: Phrase) throws -> Future<Phrase> {
        return phrase.save(on: req)
    }

    func updateHandler(_ req: Request) throws -> Future<Phrase> {
        return try flatMap(
            to: Phrase.self,
            req.parameters.next(Phrase.self),
            req.content.decode(Phrase.self)
        ) { phrase, updateData in
            phrase.title = updateData.title
            phrase.message = updateData.message

            return phrase.save(on: req)
        }
    }
}
