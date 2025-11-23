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

# Ensure we are sharing printers
cupsctl --share-printers || helpers::emergency "cupsctl" &

# Tooling
mdns::start::dbus
mdns::start::avahi
http::start

helpers::logger::log INFO "🚀 entrypoint" "starting main"
# Logs ingestion (cups cannot log to stdio)
helpers::logger::ingest INFO "🖨️cups_error" "$XDG_RUNTIME_DIR"/cups/error_log  || helpers::emergency "cups error logger" &
helpers::logger::ingest INFO "🖨️cups_access" "$XDG_RUNTIME_DIR"/cups/access_log || helpers::emergency "cups access logger" &
helpers::logger::ingest INFO "🖨️cups_page" "$XDG_RUNTIME_DIR"/cups/page_log   || helpers::emergency "cups page logger" &

# Start cupsd
cupsd -f "$@" && helpers::logger::log INFO "✅ entrypoint" "done" || helpers::emergency "error code $?" &

main_pid=$!
helpers::logger::log INFO "⌛ entrypoint" "watching ($main_pid)"
wait $main_pid
