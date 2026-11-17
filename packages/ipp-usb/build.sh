# Not in the book: the newest upstream release, built and installed as its
# Makefile does (go build with the vendored module and the
# nethttpomithttp2 tag), with /usr as the prefix.
build() {
    # Keep Go's caches inside the build directory, out of the shared build
    # root's /root; never fetch another Go toolchain.
    export GOPATH="$PWD/.gopath"
    export GOMODCACHE="$PWD/.gopath/pkg/mod"
    export GOCACHE="$PWD/.gocache"
    export GOTOOLCHAIN=local GOTELEMETRY=off
    export GOFLAGS="-mod=vendor -trimpath -buildmode=pie"
    export CGO_ENABLED=1
    go build -tags nethttpomithttp2 -ldflags "-s -w" -o ipp-usb .
}

package() {
    install -Dm755 ipp-usb "$DESTDIR/usr/sbin/ipp-usb"
    # The udev rule starts ipp-usb.service (through SYSTEMD_WANTS) when an
    # IPP-over-USB printer or scanner is plugged in, as upstream installs
    # it; the unit itself is not enabled. The unit names /sbin/ipp-usb,
    # which is the same file.
    install -Dm644 systemd-udev/71-ipp-usb.rules "$DESTDIR/usr/lib/udev/rules.d/71-ipp-usb.rules"
    install -Dm644 systemd-udev/ipp-usb.service "$DESTDIR/usr/lib/systemd/system/ipp-usb.service"
    install -Dm644 ipp-usb.conf "$DESTDIR/etc/ipp-usb/ipp-usb.conf"
    install -d "$DESTDIR/usr/share/ipp-usb/quirks"
    install -m644 ipp-usb-quirks/* "$DESTDIR/usr/share/ipp-usb/quirks/"
    # Upstream's manual page, already made from ipp-usb.8.md.
    install -Dm644 ipp-usb.8 "$DESTDIR/usr/share/man/man8/ipp-usb.8"
}
