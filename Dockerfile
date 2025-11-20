ARG           FROM_REGISTRY=docker.io/dubodubonduponey

ARG           FROM_IMAGE_TOOLS=tools:linux-trixie-2025-11-01
ARG           FROM_IMAGE_RUNTIME=base:runtime-trixie-2025-11-01

FROM          $FROM_REGISTRY/$FROM_IMAGE_TOOLS                                                                          AS builder-tools

#######################
# Running image
#######################
FROM          $FROM_REGISTRY/$FROM_IMAGE_RUNTIME

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

# Deviate avahi temporary files into /tmp (there is a socket, so, probably need exec)
RUN           mkdir -p "$XDG_RUNTIME_DIR"/avahi-daemon; ln -s "$XDG_RUNTIME_DIR"/avahi-daemon /run; chown avahi:avahi /run/avahi-daemon; chmod 777 /run/avahi-daemon

RUN           ln -sf /dev/stdout /var/log/cups/access_log && \
              ln -sf /dev/stderr /var/log/cups/error_log

# Cups requires root for anything useful
# USER          dubo-dubon-duponey

COPY          --from=builder-tools  /magnetar/bin/http-health    /magnetar/bin

EXPOSE        663

# Cups will add printers there with cupsctl
VOLUME        /etc/cups

# Used by dbus and avahi (see entrypoint.sh)
VOLUME        "$XDG_RUNTIME_DIR"

ENV           HEALTHCHECK_URL=http://localhost:631/
HEALTHCHECK   --interval=120s --timeout=10s --start-period=10s --retries=1 CMD http-health || exit 1
