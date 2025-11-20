# What

A docker image for [CUPS](https://www.cups.org/) geared towards exposing USB printers.

## Image features

 * multi-architecture:
   * [x] linux/amd64
   * [x] linux/arm64
 * hardened:
    * [x] image runs read-only
    * [x] image runs with no capabilities
    * [ ] process runs as a non-root user, disabled login, no shell
 * lightweight
    * [x] based on our slim [Debian Trixie](https://github.com/dubo-dubon-duponey/docker-debian)
    * [x] simple entrypoint script
    * [ ] multi-stage build with ~~zero packages~~ `cups`, `dbus`, `avahi-daemon`, `printer-driver-brlaser` installed in the runtime image
 * observable
    * [x] healthcheck
    * [x] log to stdout
    * [ ] ~~prometheus endpoint~~

## Run


## Notes

### Networking

You need to run this in `host` or `mac(or ip)vlan` networking (because of mDNS).

### Configuration

### Advanced configuration

### Caveats and notes

* Unclear if we need dbus or not. Too lazy to check.

## Moar?

See [DEVELOP.md](DEVELOP.md)
