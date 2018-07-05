// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "LylinkServer",
    dependencies: [
        // 💧 A server-side Swift web framework.
        .package(url: "https://github.com/vapor/vapor.git", from: "3.0.0"),

        // 🖋🐬 Swift ORM (queries, models, relations, etc) built on MySQL.
        .package(url: "https://github.com/vapor/fluent-mysql.git", from: "3.0.0-rc.4"),

        // ⚡️Non-blocking, event-driven Redis client.
        .package(url: "https://github.com/vapor/redis.git", from: "3.0.0-rc.3"),

        // 🔏 JSON Web Token signing and verification (HMAC, RSA)
        .package(url: "https://github.com/vapor/jwt.git", from: "3.0.0-rc.2"),

        // Plugin for services that use JWT authentication
        .package(url: "https://github.com/skelpo/JWTDataProvider.git", from: "0.10.1"),

        // Service for integrating JWT in Vapor apps
        .package(url: "https://github.com/skelpo/JWTVapor.git", from: "0.11.0"),

        // Collection of random Vapor middlewares
        .package(url: "https://github.com/skelpo/SkelpoMiddleware.git", from: "1.4.0")
    ],
    targets: [
        .target(name: "App", dependencies: [
            "FluentMySQL",
            "Redis",
            "JWT",
            "JWTDataProvider",
            "JWTVapor",
            "SkelpoMiddleware",
            "Vapor"
        ]),
        .target(name: "Run", dependencies: ["App"]),
        .testTarget(name: "AppTests", dependencies: ["App"])
    ]
)
