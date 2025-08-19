#!/usr/bin/env sh
set -e

# Ensure non-root if desired (reuse logic from existing entrypoint)
export PUID=${PUID:-0}
export PGID=${PGID:-0}
export GROUP_NAME="app"
export USER_NAME="app"

create_group() {
  if ! getent group ${PGID} >/dev/null 2>&1; then
    addgroup -g ${PGID} ${GROUP_NAME}
  else
    existing_group=$(getent group ${PGID} | cut -d: -f1)
    export GROUP_NAME=${existing_group}
  fi
}

create_user() {
  if ! getent passwd ${PUID} >/dev/null 2>&1; then
    adduser -u ${PUID} -G ${GROUP_NAME} -s /bin/sh -D ${USER_NAME}
  else
    existing_user=$(getent passwd ${PUID} | cut -d: -f1)
    export USER_NAME=${existing_user}
  fi
}

create_group
create_user

# Render sets $PORT for web services. Map it into LISTMONK_app__address if not provided.
if [ -n "${PORT}" ] && [ -z "${LISTMONK_app__address}" ]; then
  export LISTMONK_app__address=0.0.0.0:${PORT}
fi

# If DATABASE_URL is provided by Render, parse into LISTMONK_db__*
# Expected format: postgres://user:pass@host:port/dbname
if [ -n "${DATABASE_URL}" ]; then
  urldecode() { local data="${1//+/ }"; printf '%b' "${data//%/\\x}"; }
  rest="$(echo "$DATABASE_URL" | sed -e 's#^.*://##')"
  creds="$(echo "$rest" | cut -d@ -f1)"
  hostportdb="$(echo "$rest" | cut -d@ -f2)"
  hostport="$(echo "$hostportdb" | cut -d/ -f1)"
  qs="$(echo "$hostportdb" | awk -F'?' 'NF>1{print $2}')"
  db_host="$(echo "$hostport" | cut -d: -f1)"
  db_port="$(echo "$hostport" | cut -d: -f2)"
  db_name_encoded="$(echo "$hostportdb" | cut -d/ -f2 | cut -d? -f1)"
  db_user_encoded="$(echo "$creds" | cut -d: -f1)"
  db_pass_encoded="$(echo "$creds" | cut -d: -f2-)"
  db_user="$(urldecode "$db_user_encoded")"
  db_pass="$(urldecode "$db_pass_encoded")"
  db_name="$(urldecode "$db_name_encoded")"
  [ -n "$db_host" ] && export LISTMONK_db__host="$db_host"
  [ -n "$db_port" ] && export LISTMONK_db__port="$db_port"
  [ -n "$db_name" ] && export LISTMONK_db__database="$db_name"
  [ -n "$db_user" ] && export LISTMONK_db__user="$db_user"
  [ -n "$db_pass" ] && export LISTMONK_db__password="$db_pass"
  # sslmode from query (default to require for managed DBs)
  sslmode_q="$(echo "$qs" | tr '&' '\n' | awk -F'=' '$1=="sslmode"{print $2; found=1} END{if(!found)print ""}')"
  if [ -n "$sslmode_q" ]; then
    export LISTMONK_db__ssl_mode="$sslmode_q"
  else
    export LISTMONK_db__ssl_mode="require"
  fi
  # Pass through any other DSN params as space-separated
  params_rest="$(echo "$qs" | tr '&' '\n' | grep -v '^sslmode=' | paste -sd' ' -)"
  [ -n "$params_rest" ] && export LISTMONK_db__params="$params_rest"
fi

# Prefer env-only config unless a config file is explicitly mounted.
if [ -f /listmonk/config.toml ]; then
  CONFIG_PATH="/listmonk/config.toml"
else
  CONFIG_PATH=""
fi

# Ownership best-effort
chown -R ${PUID}:${PGID} /listmonk || true

# Install/upgrade/run chain (compatible with Render startCommand but can be the default CMD too)
if [ "$1" = "./listmonk" ]; then
  set -x
  ./listmonk --install --idempotent --yes ${CONFIG_PATH:+--config "$CONFIG_PATH"}
  ./listmonk --upgrade --yes ${CONFIG_PATH:+--config "$CONFIG_PATH"}
  exec ./listmonk ${CONFIG_PATH:+--config "$CONFIG_PATH"}
fi

exec "$@"
