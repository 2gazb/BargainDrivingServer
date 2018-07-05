import Authentication
import FluentMySQL
import JWTDataProvider
import JWTVapor
import Redis
import SkelpoMiddleware
import Vapor

/// Called before your application initializes.
public func configure(_ config: inout Config, _ env: inout Environment, _ services: inout Services) throws {
    let jwtProvider = JWTProvider { publicKey in
        guard let privateKey = Environment.get("USER_JWT_D") else {
            throw Abort(
                .internalServerError,
                reason: "Could not find environment variable 'USER_JWT_D'",
                identifier: "missingEnvVar"
            )
        }

        let headers = JWTHeader(alg: "RS256", crit: ["exp", "aud"], kid: "user_manager_kid")

        return try RSAService(n: publicKey, e: "AQAB", d: privateKey, header: headers)
    }

    /// Register providers first
    try services.register(AuthenticationProvider())
    try services.register(FluentMySQLProvider())
    try services.register(StorageProvider())
    try services.register(jwtProvider)

    /// Register routes to the router
    let router = EngineRouter.default()
    try routes(router)
    services.register(router, as: Router.self)

    /// Register middleware
    var middlewares = MiddlewareConfig() // Create _empty_ middleware config
    // middlewares.use(FileMiddleware.self) // Serves files from `Public/` directory
    middlewares.use(ErrorMiddleware.self) // Catches errors and converts to HTTP response

    // Catches all errors and formats them in a JSON response
    middlewares.use(APIErrorMiddleware(environment: env, specializations: [
        ModelNotFound(),
        DecodingTypeMismatch()
    ]))
    services.register(middlewares)

    try configureDatabases(env, &services)

    /// Configure migrations
    var migrations = MigrationConfig()
    migrations.add(model: Phrase.self, database: .mysql)
    migrations.add(model: User.self, database: .mysql)
    services.register(migrations)

    /// Configure the rest of your application here
    var commandConfig = CommandConfig.default()
    commandConfig.useFluentCommands()
    commandConfig.use(CreateSuperadminCommand(), as: "superadmin")
    services.register(commandConfig)

    let jwt = JWTDataConfig()
    services.register(jwt)
}

// MARK: - Databases
// swiftlint:disable:next function_body_length
private func configureDatabases(_ env: Environment, _ services: inout Services) throws {
    // MARK: - MySQL
    // Configure a MySQL database
    let mysqlConfig: MySQLDatabaseConfig

    if
        let url = Environment.get("DATABASE_URL"),
        let config = try MySQLDatabaseConfig(url: url)
    {
        mysqlConfig = config
    } else {
        let databaseName: String
        let databasePort: Int

        if env == .testing {
            databaseName = "vapor-test"

            if let testPort = Environment.get("DATABASE_PORT") {
                databasePort = Int(testPort) ?? 3307
            } else {
                databasePort = 3307
            }
        } else {
            databaseName = Environment.get("DATABASE_DB") ?? "vapor"
            databasePort = 3306
        }

        let databaseHostname = Environment.get("DATABASE_HOSTNAME") ?? "127.0.0.1"
        let databaseUsername = Environment.get("DATABASE_USERNAME") ?? "vapor"
        let databasePassword = Environment.get("DATABASE_PASSWORD") ?? "password"

        mysqlConfig = MySQLDatabaseConfig(
            hostname: databaseHostname,
            port: databasePort,
            username: databaseUsername,
            password: databasePassword,
            database: databaseName
        )
    }

    let mysql = MySQLDatabase(config: mysqlConfig)

    // MARK: - Redis
    let redisHostname = Environment.get("REDIS_HOSTNAME") ?? "localhost"
    let redisPort: Int

    if env == .testing {
        if let testPort = Environment.get("REDIS_PORT") {
            redisPort = Int(testPort) ?? 6380
        } else {
            redisPort = 6380
        }
    } else {
        redisPort = 6379
    }

    let redisURL = URL(string: "http://\(redisHostname):\(redisPort)")!
    let redis = try RedisDatabase(url: redisURL)

    /// Register the configured SQLite database to the database config.
    var databases = DatabasesConfig()
    databases.add(database: mysql, as: .mysql)
    databases.add(database: redis, as: .redis)
    services.register(databases)
}
