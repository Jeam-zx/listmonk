# --- Builder stage: build frontend and Go binary ---
FROM golang:1.22-alpine AS builder
RUN apk add --no-cache git build-base nodejs npm yarn make bash
WORKDIR /src

# Pre-cache Go modules
COPY go.mod go.sum ./
RUN go mod download

# Copy the rest of the source
COPY . .

# Build the binary and pack frontend assets into it
RUN make dist

# --- Runtime stage ---
FROM alpine:latest
RUN apk --no-cache add ca-certificates tzdata shadow su-exec bash
WORKDIR /listmonk

# Copy the built binary
COPY --from=builder /src/listmonk /listmonk/listmonk

# Optionally include sample config for reference
COPY config.toml.sample /listmonk/config.toml.sample

# Copy entrypoints
COPY docker-entrypoint.sh /usr/local/bin/
COPY docker-entrypoint.render.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.render.sh

EXPOSE 9000
ENTRYPOINT ["docker-entrypoint.render.sh"]
CMD ["./listmonk"]
