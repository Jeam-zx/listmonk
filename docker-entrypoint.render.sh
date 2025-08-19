#!/usr/bin/env sh
set -e

if [ -z "${DATABASE_URL:-}" ]; then
  echo "DATABASE_URL is required" >&2
  exit 1
fi

PORT="${PORT:-9000}"
APP_ADDR="0.0.0.0:${PORT}"

# Soporta postgres:// o postgresql://
url="$DATABASE_URL"
rest="${url#*://}"
up="${rest%%@*}"
hp="${rest#*@}"

user="${up%%:*}"
pass="${up#*:}"
hostport="${hp%%/*}"
dbandparams="${hp#*/}"
db="${dbandparams%%\?*}"
params=""
case "$dbandparams" in *\?*) params="${dbandparams#*\?}";; esac
host="${hostport%%:*}"
port="${hostport#*:}"; [ "$port" = "$hostport" ] && port="5432"

# Por defecto sin TLS (si la URL trae sslmode se respeta)
ssl_mode="disable"
if [ -n "$params" ]; then
  sm="$(printf "%s" "$params" | tr '&' '\n' | grep -E '^sslmode=' | tail -n1 | cut -d= -f2 || true)"
  [ -n "$sm" ] && ssl_mode="$sm"
fi

cat > /listmonk/config.toml <<EOF
[app]
address = "${APP_ADDR}"

[db]
host = "${host}"
port = ${port}
user = "${user}"
password = "${pass}"
database = "${db}"
ssl_mode = "${ssl_mode}"
max_open = 25
max_idle = 25
max_lifetime = "300s"
params = ""
EOF

echo "Installing/upgrading DB ..."
/listmonk/listmonk --install --idempotent --yes --config /listmonk/config.toml || true
/listmonk/listmonk --upgrade --yes --config /listmonk/config.toml || true

echo "Starting listmonk on ${APP_ADDR} ..."
exec /listmonk/listmonk --config /listmonk/config.toml