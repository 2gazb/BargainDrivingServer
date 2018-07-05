import Vapor

struct APIController: RouteCollection {
    func boot(router: Router) throws {
        let apiRoutes = router.grouped("api")
        let v1Controller = V1Controller()

        try apiRoutes.register(collection: v1Controller)
    }
}
