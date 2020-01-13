FROM golang:1.13 as builder

RUN mkdir -p /service/

WORKDIR /service

COPY . .

RUN go mod download

RUN go test -v -race ./...

RUN GIT_COMMIT=$(git rev-list -1 HEAD) && \
    CGO_ENABLED=0 GOOS=linux go build -ldflags "-s -w \
    -X github.com/cybervagabond/service/pkg/version.REVISION=${GIT_COMMIT}" \
    -a -o bin/service cmd/service/*

RUN GIT_COMMIT=$(git rev-list -1 HEAD) && \
    CGO_ENABLED=0 GOOS=linux go build -ldflags "-s -w \
    -X github.com/cybervagabond/service/pkg/version.REVISION=${GIT_COMMIT}" \
    -a -o bin/podcli cmd/podcli/*

FROM alpine:3.10

RUN addgroup -S app \
    && adduser -S -g app app \
    && apk --no-cache add \
    curl openssl netcat-openbsd

WORKDIR /home/app

COPY --from=builder /service/bin/service .
COPY --from=builder /service/bin/podcli /usr/local/bin/podcli
COPY ./ui ./ui
RUN chown -R app:app ./

USER app

CMD ["./service"]
