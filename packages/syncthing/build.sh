# Not in the book: the newest upstream release. Built with "go build" of
# cmd/syncthing, with the tags and version stamp that "go run build.go
# -no-upgrade build" would use, from the vendored modules (no network). The
# web GUI assets (lib/api/auto/gui.files.go) are prebuilt in the archive, so
# build.go's asset step is not needed.
build() {
    # Keep Go's build cache inside the build directory, out of the shared
    # build root's /root; never fetch another Go toolchain or module.
    export GOPATH="$PWD/.gopath"
    export GOCACHE="$PWD/.gocache"
    export GOTOOLCHAIN=local GOTELEMETRY=off GOPROXY=off
    export GOFLAGS="-mod=vendor -trimpath -buildmode=pie"
    export CGO_ENABLED=1
    # noupgrade: the package manager, not syncthing's automatic upgrade,
    # replaces this binary. libsqlite3: link the system SQLite.
    local tags="noupgrade libsqlite3"
    # build.go stamps the release time from git; the archive's RELEASE file
    # carries the same date and keeps the build reproducible.
    local stamp
    stamp=$(stat -c %Y RELEASE)
    local pkg=github.com/syncthing/syncthing/lib/build
    go build -tags "$tags" \
        -ldflags "-w -buildid= -X $pkg.Version=v$PKG_VERSION -X $pkg.Stamp=$stamp -X $pkg.User=dave -X $pkg.Host=joe -X $pkg.Tags=${tags// /,}" \
        -o syncthing ./cmd/syncthing
}

package() {
    install -Dm755 syncthing "$DESTDIR/usr/bin/syncthing"

    # What upstream's own Debian package (build.go, installationFiles)
    # installs besides the binary: manual pages, the units (not enabled), the
    # larger UDP buffers QUIC wants, the ufw application profile, desktop
    # entries and icons.
    install -d "$DESTDIR/usr/share/man/man1" "$DESTDIR/usr/share/man/man5" "$DESTDIR/usr/share/man/man7"
    install -m644 man/syncthing.1 "$DESTDIR/usr/share/man/man1/"
    install -m644 man/syncthing-config.5 man/syncthing-stignore.5 "$DESTDIR/usr/share/man/man5/"
    install -m644 man/syncthing-*.7 "$DESTDIR/usr/share/man/man7/"
    install -Dm644 etc/linux-systemd/system/syncthing@.service "$DESTDIR/usr/lib/systemd/system/syncthing@.service"
    install -Dm644 etc/linux-systemd/user/syncthing.service "$DESTDIR/usr/lib/systemd/user/syncthing.service"
    install -Dm644 etc/linux-sysctl/30-syncthing.conf "$DESTDIR/usr/lib/sysctl.d/30-syncthing.conf"
    install -Dm644 etc/firewall-ufw/syncthing "$DESTDIR/etc/ufw/applications.d/syncthing"
    install -Dm644 etc/linux-desktop/syncthing-start.desktop "$DESTDIR/usr/share/applications/syncthing-start.desktop"
    install -Dm644 etc/linux-desktop/syncthing-ui.desktop "$DESTDIR/usr/share/applications/syncthing-ui.desktop"
    local size
    for size in 32 64 128 256 512; do
        install -Dm644 "assets/logo-$size.png" "$DESTDIR/usr/share/icons/hicolor/${size}x$size/apps/syncthing.png"
    done
    install -Dm644 assets/logo-only.svg "$DESTDIR/usr/share/icons/hicolor/scalable/apps/syncthing.svg"
}
