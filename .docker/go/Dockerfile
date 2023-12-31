FROM golang:1.20-alpine as builder

RUN apk --no-cache add gcc musl-dev

WORKDIR /app

# キャッシュを利用するため先に/go/pkg/modにインストール
COPY ./app/go.mod ./app/go.sum ./
RUN go mod download

COPY ./app/ .

# パスとデバッグ情報を削除してバイナリを軽量化
RUN go build -trimpath -ldflags "-w -s" -o ./main ./main.go

FROM alpine:3.17 as runner

RUN apk update && \
    apk add --no-cache shadow curl && \
    useradd -m appuser && \
    rm -f /usr/bin/gpasswd /usr/bin/passwd /usr/bin/chfn /sbin/unix_chkpwd /usr/bin/expiry /usr/bin/chage /usr/bin/chsh && \
    rm -rf /var/cache/apk/*

USER appuser

WORKDIR /app
COPY --from=builder /app/main .

RUN touch .env && chown appuser:appuser .env

CMD ["./main"]

FROM golang:1.20-alpine3.17 as dev

ENV CGO_ENABLED 0
ENV GO111MODULE auto

RUN apk --no-cache add git

WORKDIR /app
COPY ./app/ .