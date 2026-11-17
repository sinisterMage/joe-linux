# Not in the book: the newest upstream release, built with build_linux.sh
# and the flags of upstream's release workflow (no cgo, the version
# stamped in). The plugins go in /usr/lib/cni, as other distributions put
# them, rather than the conventional /opt/cni/bin; containerd's
# configuration in the containerd package points there.
build() {
    # Keep Go's module and build caches inside the build directory, out of
    # the shared build root's /root; never fetch another Go toolchain.
    export GOPATH="$PWD/.gopath"
    export GOMODCACHE="$PWD/.gopath/pkg/mod"
    export GOCACHE="$PWD/.gocache"
    export GOTOOLCHAIN=local GOTELEMETRY=off
    export GOFLAGS="-mod=readonly -modcacherw -trimpath -buildmode=pie"
    export CGO_ENABLED=0
    ./build_linux.sh -ldflags "-s -w -X github.com/containernetworking/plugins/pkg/utils/buildversion.BuildVersion=v$PKG_VERSION"
}

package() {
    install -d "$DESTDIR/usr/lib/cni"
    install -m755 bin/* "$DESTDIR/usr/lib/cni/"

    # Upstream's socket-activated units for the dhcp plugin's daemon,
    # pointed at where it is installed. Not enabled.
    install -d "$DESTDIR/usr/lib/systemd/system"
    sed 's|/opt/cni/bin/|/usr/lib/cni/|' plugins/ipam/dhcp/systemd/cni-dhcp.service \
        > "$DESTDIR/usr/lib/systemd/system/cni-dhcp.service"
    install -m644 plugins/ipam/dhcp/systemd/cni-dhcp.socket "$DESTDIR/usr/lib/systemd/system/"
}
