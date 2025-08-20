# Build (Go + Node; produce binario según TARGETOS/TARGETARCH)
FROM golang:1.24-bookworm AS builder
WORKDIR /src
ARG TARGETOS TARGETARCH
ENV GOTOOLCHAIN=auto \
    GOOS=${TARGETOS} \
    GOARCH=${TARGETARCH} \
    CGO_ENABLED=0
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl git make gcc g++ pkg-config gnupg file && \
    rm -rf /var/lib/apt/lists/*
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get update && apt-get install -y --no-install-recommends nodejs && \
    npm i -g yarn
# Configura registry y timeouts + retries para npm/yarn
ENV YARN_NETWORK_TIMEOUT=600000 \
    npm_config_registry=https://registry.npmjs.org \
    npm_config_fetch_retries=5 \
    npm_config_fetch_retry_maxtimeout=120000 \
    npm_config_fetch_retry_mintimeout=20000
RUN yarn config set registry https://registry.npmjs.org
COPY . .
ENV CI=1
# Asegura no usar binario previo
RUN rm -f /src/listmonk
RUN test -f frontend/.gitignore || printf "# generated for CI\n" > frontend/.gitignore
# Reintentos por fallos de red
RUN set -e; for i in 1 2 3 4 5; do make dist && break || { code=$?; echo "make dist failed (exit $code), retry $i/5"; sleep 10; }; done
# Si el Make dejó el binario dentro de dist/, cópialo a /src/listmonk
RUN if [ ! -x /src/listmonk ]; then \
      f="$(find /src/dist -type f -name listmonk -path '*linux*amd64*' | head -n1)"; \
      [ -n "$f" ] && cp "$f" /src/listmonk; \
    fi
# Verifica que sea ELF x86_64 (Linux)
RUN file /src/listmonk && file /src/listmonk | grep -E "ELF 64-bit.*x86-64"

# Runtime
FROM debian:bookworm-slim
RUN useradd -r -u 10001 -m listmonk && \
    apt-get update && apt-get install -y --no-install-recommends ca-certificates tzdata && \
    rm -rf /var/lib/apt/lists/*
WORKDIR /listmonk
COPY --from=builder /src/listmonk /listmonk/listmonk
COPY --from=builder /src/config.toml.sample /listmonk/config.toml.sample
COPY docker-entrypoint.render.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /listmonk/listmonk /usr/local/bin/entrypoint.sh && \
    chown -R listmonk:listmonk /listmonk
# Chequeo en runtime
RUN /listmonk/listmonk --version || (echo "binario no ejecuta" >&2; exit 1)
ENV PORT=9000
EXPOSE 9000
USER listmonk
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
