# lylink_server

To install dependencies:

```shell
brew install sourcery swiftlint
```

To regenerate Xcode project:

```shell
./xc
```

To update dependencies and regenerate Xcode project:

```shell
# Bash
vapor update && ./xc

# Fish
vapor update; and ./xc
```

To prepare local MySQL database for regular development:

```shell
docker container run --name mysql -e MYSQL_DATABASE=vapor -e MYSQL_USER=vapor -e MYSQL_PASSWORD=password -e MYSQL_ROOT_PASSWORD=password -p 3306:3306 -d mysql:5
```

To prepare local Redis instance for regular development:

```shell
docker container run --name redis -p 6379:6379 -d redis
```

To run test suite on Linux in Docker:

```shell
docker-compose up --build --abort-on-container-exit
```

Required environmental variables:

- `JWT_SECRET` – the `n` value of the JWK (for local development, you can generate your own at [mkjwk.org](https://mkjwk.org/), `ks`: `2048`, `ku`: `sig`, `alg`: `rs256`, `kid`: `user_manager_kid`)
- `USER_JWT_D` - the `d` value of the JWK

Optional environmental variables:

- `DATABASE_URL` – takes precedence over the values listed below, but must be well-formed (otherwise expect a crash)
- `DATABASE_HOSTNAME`
- `DATABASE_PORT`
- `DATABASE_USERNAME`
- `DATABASE_PASSWORD`
- `REDIS_HOSTNAME`
- `REDIS_PORT`
# BargainDrivingServer
