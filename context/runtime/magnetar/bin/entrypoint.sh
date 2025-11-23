#!/usr/bin/env bash
set -o errexit -o errtrace -o functrace -o nounset -o pipefail

trap 'exit 1' TERM

root="$(cd "$(dirname "${BASH_SOURCE[0]:-$PWD}")" 2>/dev/null 1>&2 && pwd)"
readonly root
# shellcheck source=/dev/null
. "$root/helpers.sh"
# shellcheck source=/dev/null
. "$root/mdns.sh"
# shellcheck source=/dev/null
. "$root/http.sh"

helpers::logger::set LOG_LEVEL
helpers::logger::log INFO "🎬 entrypoint" "starting container"

# Necessary for adding printers with lpadmin
helpers::dir::writable "$XDG_CONFIG_HOME"/cups
# Ensure runtime dir is here
helpers::dir::writable "$XDG_RUNTIME_DIR"/cups create
helpers::dir::writable "$XDG_CACHE_HOME"/cups create

# Tooling
mdns::start::dbus
mdns::start::avahi
# Experimental caddy front
[ "$MOD_HTTP_ENABLED" != true ] || http::start

helpers::logger::log INFO "🚀 entrypoint" "starting main"
# Logs ingestion (cups cannot log to stdio)
helpers::logger::ingest INFO "🖨️cups_error" "$XDG_RUNTIME_DIR"/cups/error_log  || helpers::emergency "cups error logger" "error code $?" &
helpers::logger::ingest INFO "🖨️cups_access" "$XDG_RUNTIME_DIR"/cups/access_log || helpers::emergency "cups access logger" "error code $?" &
helpers::logger::ingest INFO "🖨️cups_page" "$XDG_RUNTIME_DIR"/cups/page_log   || helpers::emergency "cups page logger" "error code $?" &

# Start cupsd
cupsd -f "$@" &
main_pid=$!

tries=1
# Ensure we are sharing printers
until [ -e "$XDG_RUNTIME_DIR"/cups/cups.sock ]; do
  sleep 1s
  tries=$(( tries + 1))
  [ $tries -lt 10 ] || {
    helpers::logger::log ERROR "🖨️cupsctl" "failed waiting for socket in a reasonable time"
    exit 1
  }
done

cupsctl --share-printers --remote-any || helpers::emergency "cupsctl" "error code $?" &

helpers::logger::log INFO "⌛ entrypoint" "watching ($main_pid)"
wait $main_pid
