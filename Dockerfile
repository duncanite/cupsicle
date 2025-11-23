ARG           FROM_REGISTRY=docker.io/dubodubonduponey

ARG           FROM_IMAGE_TOOLS=tools:linux-trixie-2025-11-01
ARG           FROM_IMAGE_RUNTIME=base:runtime-trixie-2025-11-01

FROM          $FROM_REGISTRY/$FROM_IMAGE_TOOLS                                                                          AS builder-tools

#######################
# Running image
#######################
FROM          $FROM_REGISTRY/$FROM_IMAGE_RUNTIME

ENV           _SERVICE_PORT=631

USER          root

# Avahi, cups, and driver
RUN           --mount=type=secret,uid=42,id=CA \
              --mount=type=secret,uid=42,id=CERTIFICATE \
              --mount=type=secret,uid=42,id=KEY \
              --mount=type=secret,uid=42,id=GPG.gpg \
              --mount=type=secret,id=NETRC \
              --mount=type=secret,id=APT_SOURCES \
              --mount=type=secret,id=APT_CONFIG \
              apt-get update -qq && \
              apt-get install -qq --no-install-recommends \
                dbus=1.16.2-2 \
                avahi-daemon=0.8-16 \
                cups=2.4.10-3+deb13u1 \
                printer-driver-brlaser=6.2.7-1 && \
              apt-get -qq autoremove      && \
              apt-get -qq clean           && \
              rm -rf /var/lib/apt/lists/* && \
              rm -rf /tmp/*               && \
              rm -rf /var/tmp/*

# Deviate avahi
#RUN           mkdir -p "$XDG_RUNTIME_DIR"/avahi-daemon && \
#              ln -s "$XDG_RUNTIME_DIR"/avahi-daemon /run && \
#              chmod 777 /run/avahi-daemon && \
#              chown avahi:avahi /run/avahi-daemon

# Avahi special dealing. See notes in mdns.sh
RUN           mkdir -p /run/avahi-daemon && \
              chmod 777 /run/avahi-daemon && \
              chown avahi:avahi /run/avahi-daemon

# Yes, it will create an anonymous volume
VOLUME        /run/avahi-daemon

# 1. Add user to lp groups
# 2. Fix debian package executable permission insanity - make up your mind debian. socket is "fine" but braille and usb "danger danger"?
# 3. Disable cups basic authentication
#    Disable require user entirely
#    Change log level
# 4. Ensure permissions are correct on config
# 5. Deviate cups logs, cache, spool, run, config
#    Note: for logs, we cannot symlink to stdout because CUPS is not happy with that (re: buffering)

RUN           sed -i "/^lpadmin:/s/$/,dubo-dubon-duponey/; /^lp:/s/$/,dubo-dubon-duponey/" /etc/group; \
              chmod 755 /usr/lib/cups/backend/*; \
              sed -i \
                -e 's/^DefaultAuthType Basic/DefaultAuthType None/' \
                -e '/Require user @SYSTEM/d' \
                -e 's/LogLevel warn/LogLevel info/' \
                /etc/cups/cupsd.conf; \
              chown -R dubo-dubon-duponey "/etc/cups"; \
              rm -Rf /var/log/cups; \
              rm -Rf /var/cache/cups; \
              rm -Rf /var/spool/cups; \
              rm -Rf /run/cups; \
              mv /etc/cups "$XDG_CONFIG_HOME"/cups; \
              ln -s "$XDG_RUNTIME_DIR"/cups /var/log/cups; \
              ln -s "$XDG_CACHE_HOME"/cups /var/cache/cups; \
              ln -s "$XDG_CACHE_HOME"/cups /var/spool/cups; \
              ln -s "$XDG_RUNTIME_DIR"/cups /run/cups; \
              ln -s "$XDG_CONFIG_HOME"/cups /etc/cups

USER          dubo-dubon-duponey

COPY          --from=builder-tools  /magnetar/bin/http-health /magnetar/bin
COPY          --from=builder-tools  /magnetar/bin/caddy       /magnetar/bin
# Docker does not need this, but nerdctl might
#RUN           setcap 'cap_net_bind_service+ep' /magnetar/bin/caddy; \
#              setcap 'cap_net_bind_service+ep' /usr/sbin/cupsd

EXPOSE        $_SERVICE_PORT
EXPOSE        443

# The following volumes are necessary:
# Used by dbus and avahi, and also for logs from cups
#VOLUME        "$XDG_RUNTIME_DIR"
# Used by Caddy to store certificates
#VOLUME        "$XDG_DATA_HOME"
# Config for cups and caddy (mutable)
#VOLUME        "$XDG_CONFIG_HOME"

ENV           HEALTHCHECK_URL=http://127.0.0.1/
HEALTHCHECK   --interval=120s --timeout=30s --start-period=10s --retries=1 CMD http-health || exit 1
