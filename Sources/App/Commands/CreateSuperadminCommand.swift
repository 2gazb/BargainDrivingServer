import Command
import Crypto

struct CreateSuperadminCommand: Command, Service {
    var arguments: [CommandArgument] {
        return [
            .argument(name: "username"),
            .argument(name: "firstName"),
            .argument(name: "lastName"),
            .argument(name: "password")
        ]
    }

    var options: [CommandOption] {
        return []
    }

    var help: [String] {
        return ["Create a superadmin account with provided credentials"]
    }

    init() {}

    func run(using context: CommandContext) throws -> Future<Void> {
        let username = try context.argument("username")
        let firstName = try context.argument("firstName")
        let lastName = try context.argument("lastName")
        let password = try context.argument("password")
        let user = User(username, firstName, lastName, password)

        user.password = try BCrypt.hash(user.password)
        user.permissionLevel = .superadmin

        return context.container.withPooledConnection(to: .mysql) { db in
            return user.save(on: db).transform(to: ())
        }
    }
}
