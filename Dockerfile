# Build (Go + Node para empaquetar frontend en el binario)
FROM golang:1.22-bookworm AS builder
WORKDIR /src
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl git make gcc g++ pkg-config gnupg && \
    rm -rf /var/lib/apt/lists/*
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get update && apt-get install -y --no-install-recommends nodejs && \
    npm i -g yarn
COPY . .
ENV CI=1
RUN make dist

# Runtime mínimo
FROM debian:bookworm-slim
RUN useradd -r -u 10001 -m listmonk && \
    apt-get update && apt-get install -y --no-install-recommends ca-certificates tzdata && \
    rm -rf /var/lib/apt/lists/*
WORKDIR /listmonk
COPY --from=builder /src/listmonk /listmonk/listmonk
COPY --from=builder /src/config.toml.sample /listmonk/config.toml.sample
COPY docker-entrypoint.render.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /listmonk/listmonk /usr/local/bin/entrypoint.sh
ENV PORT=9000
EXPOSE 9000
USER listmonk
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
