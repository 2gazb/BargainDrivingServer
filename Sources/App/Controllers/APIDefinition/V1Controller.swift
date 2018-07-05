import Vapor

struct V1Controller: RouteCollection {
    func boot(router: Router) throws {
        let v1Routes = router.grouped("v1")
        let userController = UserController()
        let phraseController = PhraseController()

        try v1Routes.register(collection: userController)
        try v1Routes.register(collection: phraseController)
    }
}
