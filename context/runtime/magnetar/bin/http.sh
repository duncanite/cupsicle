#!/usr/bin/env bash
set -o errexit -o errtrace -o functrace -o nounset -o pipefail

http::certificate(){
  printf >&2 "Displaying root certificate to trust\n"
  if [ ! -e "$XDG_DATA_HOME"/caddy/pki/authorities/local/root.crt ]; then
    helpers::logger::log ERROR "🌐 http" "No root certificate installed or generated. Run the container so that a cert is generated, or provide one at runtime."
    exit 1
  fi
  cat "$XDG_DATA_HOME"/caddy/pki/authorities/local/root.crt
}

http::start(){
  helpers::logger::log INFO "🌐 http" "starting"

  # Caddy wants to write config there
  helpers::dir::writable "$XDG_CONFIG_HOME/caddy" create
  # And certificates there
  helpers::dir::writable "$XDG_DATA_HOME/caddy" create

  {
    caddy run --config "$XDG_CONFIG_DIRS"/caddy/main.conf --adapter caddyfile "$@" \
      > >(helpers::logger::slurp INFO "🌐 http") \
      2> >(helpers::logger::slurp DEBUG "🌐 http")
  } && helpers::logger::log INFO "🌐 http" "stopped properly" \
    || helpers::emergency "🌐 http" "error code $?" &
}
