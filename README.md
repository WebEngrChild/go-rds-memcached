# Getting Started

## Dev
```shell
$ docker compose up -d
$ docker compose exec app go run main.go
```

## Prod
```shell:
$ docker build --no-cache --target runner -t go-dev-repo --platform linux/amd64 -f ./.docker/go/Dockerfile .
```

# Apache Bench

```shell
$ ab -n 10 -c 10 http://localhost:8080/db/1
$ ab -n 10 -c 10 http://localhost:8080/cache/1
```