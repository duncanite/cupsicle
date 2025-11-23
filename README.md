# Cupsicle

Cupsicle is a container image for [CUPS](https://www.cups.org/), primarily geared towards exposing legacy USB printers.

It is particularly focused on container hardening.

## Image features

 * multi-architecture:
   * [x] linux/amd64
   * [x] linux/arm64
 * hardened:
    * [x] image runs read-only
    * [x] image runs with no capabilities
    * [x] process runs as a non-root user, disabled login, no shell
 * lightweight
    * [x] based on our slim [Debian Trixie](https://github.com/dubo-dubon-duponey/docker-debian)
    * [x] simple entrypoint script
    * [ ] multi-stage build with ~~zero packages~~ `cups`, `dbus`, `avahi-daemon`, `printer-driver-brlaser` installed in the runtime image
 * observable
    * [x] healthcheck
    * [x] log to stdout
    * [ ] ~~prometheus endpoint~~

## Run


## Discovering and installing printers

From inside the container:

```bash
# List visible printers
dubo-dubon-duponey@print:/$ lpinfo -v
network beh
network ipps
network https
network http
network lpd
network ipp
network socket
direct usb://Brother/HL-L2340D%20series

# Get the right driver, if needed (use "anywhere" for modern printers)
dubo-dubon-duponey@print:/$ lpinfo -m | grep "Brother HL-L2340"
drv:///brlaser.drv/brl2340d.ppd Brother HL-L2340D series, using Owl-Maintain/brlaser v6.2.7

# Install the printer
dubo-dubon-duponey@print:/$ lpadmin -p "Magnetosphere" \
    -D "Magnetosphere" \
    -L "Dirty Laundry" \
    -v "usb://Brother/HL-L2340D%20series" \
    -m drv:///brlaser.drv/brl2340d.ppd \
    -u allow:all \
    -o cupsIPPSupplies=true \
    -o cupsSNMPSupplies=true \
    -o PageSize=Legal \
    -E
lpadmin: Printer drivers are deprecated and will stop working in a future version of CUPS.

# Review printer options
dubo-dubon-duponey@print:/$ lpoptions -p Magnetosphere -l
PageSize/Media Size: A4 A5 A6 B5 B6 EnvC5 EnvMonarch EnvDL Executive *Legal Letter
Resolution/Resolution: *600dpi 1200dpi
InputSlot/Media Source: *Auto Tray1 Tray2 Tray3 MPTray Manual
MediaType/Media Type: *PLAIN THIN THICK THICKER BOND TRANS ENV ENV-THICK ENV-THIN
brlaserEconomode/Toner save mode: *False True
Duplex/2-Sided Printing: *None DuplexNoTumble DuplexTumble
```

## Notes

### Networking

You need to run this in `host` or `mac(or ip)vlan` networking (because of mDNS).

### Configuration

### Advanced configuration

## Moar?

See [DEVELOP.md](DEVELOP.md)
