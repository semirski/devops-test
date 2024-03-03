FROM golang:1.21-alpine AS builder

WORKDIR /build
COPY . .
RUN go mod download
RUN go build -o ./test

FROM alpine:3.19

WORKDIR /app
COPY --from=builder /build/test ./test
COPY *.html .
COPY stylesheets/ ./stylesheets/

EXPOSE 3000

CMD ["/app/test"]
