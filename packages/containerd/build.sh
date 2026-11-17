# Not in the book: the newest upstream release, built with its Makefile as
# its BUILDING.md describes, from the vendored modules, with upstream's
# default build tags: every snapshotter (btrfs, devmapper, zfs among them)
# and the CRI plugin. The shim is static, as upstream builds it.
# b7a25261... is the commit v2.4.2 points to, which the Makefile would take
# from git.
prepare() {
    # The CRI plugin looks for CNI plugins in /opt/cni/bin by default;
    # cni-plugins installs them in /usr/lib/cni.
    sed -i 's|"/opt/cni/bin"|"/usr/lib/cni"|' internal/cri/config/config_unix.go
}

go_env() {
    # Go's caches in the build directory, outside the source tree; never
    # fetch another Go toolchain. The Makefile runs go list when it is
    # read, so this is needed for every make.
    export GOPATH=/build/go
    export GOCACHE=/build/go/cache
    export GOTOOLCHAIN=local GOTELEMETRY=off
    # The Makefile adds -buildmode=pie itself, except for the static shim.
    export GOFLAGS="-mod=vendor -trimpath"
}

build() {
    go_env
    local vars=(VERSION="v$PKG_VERSION" REVISION=b7a25261e029d68978bbf290df0a62fc819b3c51)
    make "${vars[@]}" binaries
    make "${vars[@]}" man

    # Upstream's default configuration, as containerd itself prints it
    # (docs/getting-started.md).
    bin/containerd config default > config.toml
}

package() {
    go_env
    make PREFIX=/usr DESTDIR="$DESTDIR" install
    # install-man would gzip them; the man pages are installed as they are.
    install -d "$DESTDIR/usr/share/man/man5" "$DESTDIR/usr/share/man/man8"
    install -m644 man/*.5 "$DESTDIR/usr/share/man/man5/"
    install -m644 man/*.8 "$DESTDIR/usr/share/man/man8/"
    install -Dm644 contrib/autocomplete/ctr "$DESTDIR/usr/share/bash-completion/completions/ctr"
    install -Dm644 contrib/autocomplete/zsh_autocomplete "$DESTDIR/usr/share/zsh/site-functions/_ctr"

    install -Dm644 config.toml "$DESTDIR/etc/containerd/config.toml"

    # Upstream's unit, pointed at where containerd is installed. Not
    # enabled.
    install -d "$DESTDIR/usr/lib/systemd/system"
    sed -e 's|/usr/local/bin/containerd|/usr/bin/containerd|' \
        -e 's|/sbin/modprobe|/usr/sbin/modprobe|' \
        containerd.service > "$DESTDIR/usr/lib/systemd/system/containerd.service"
}
