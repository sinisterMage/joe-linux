# Not in the book: the newest upstream release, built as its Makefile and
# Makefile.release build release binaries: without cgo, with the
# grpcnotrace tag, and the commit stamped into coremain.GitCommit (it is
# printed by coredns -version). The plugin list (plugin.cfg) is the
# default one, already generated into core/plugin/zplugin.go.
build() {
    # Keep Go's module and build caches inside the build directory, out of
    # the shared build root's /root; never fetch another Go toolchain (the
    # Makefile would ask for exactly the one in .go-version).
    export GOPATH="$PWD/.gopath"
    export GOMODCACHE="$PWD/.gopath/pkg/mod"
    export GOCACHE="$PWD/.gocache"
    export GOTOOLCHAIN=local GOTELEMETRY=off
    export GOFLAGS="-mod=readonly -modcacherw -trimpath -buildmode=pie"
    export CGO_ENABLED=0
    grep -q "CoreVersion = \"$PKG_VERSION\"" coremain/version.go
    # The commit tagged v1.15.0, abbreviated as git describe gives it.
    go build -tags grpcnotrace \
        -ldflags "-s -w -X github.com/coredns/coredns/coremain.GitCommit=a6fde3f" \
        -o coredns
}

package() {
    install -Dm755 coredns "$DESTDIR/usr/bin/coredns"

    # The manual pages upstream generated: coredns(1), corefile(5) and one
    # coredns-PLUGIN(7) per plugin.
    install -d "$DESTDIR/usr/share/man/man1" "$DESTDIR/usr/share/man/man5" "$DESTDIR/usr/share/man/man7"
    install -m644 man/*.1 "$DESTDIR/usr/share/man/man1/"
    install -m644 man/*.5 "$DESTDIR/usr/share/man/man5/"
    install -m644 man/*.7 "$DESTDIR/usr/share/man/man7/"

    # A first configuration: a caching forwarder to the resolvers in
    # /etc/resolv.conf. With systemd-resolved's stub listening on
    # 127.0.0.53, bind CoreDNS to other addresses (the bind plugin).
    install -d "$DESTDIR/etc/coredns"
    cat > "$DESTDIR/etc/coredns/Corefile" << "EOF2"
# See corefile(5) and coredns-PLUGIN(7).
. {
    forward . /etc/resolv.conf
    cache
    errors
    log
}
EOF2

    # The unit, account and state directory of upstream's coredns/deployment
    # repository (systemd/), logging to the journal rather than to files in
    # /var/log. Not enabled.
    install -d "$DESTDIR/usr/lib/systemd/system" "$DESTDIR/usr/lib/sysusers.d" "$DESTDIR/usr/lib/tmpfiles.d"
    cat > "$DESTDIR/usr/lib/systemd/system/coredns.service" << "EOF2"
[Unit]
Description=CoreDNS DNS server
Documentation=https://coredns.io
After=network.target

[Service]
LimitNOFILE=1048576
LimitNPROC=512
CapabilityBoundingSet=CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_BIND_SERVICE
NoNewPrivileges=true
User=coredns
WorkingDirectory=/var/lib/coredns
ExecStart=/usr/bin/coredns -conf=/etc/coredns/Corefile
ExecReload=/usr/bin/kill -SIGUSR1 $MAINPID
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF2
    cat > "$DESTDIR/usr/lib/sysusers.d/coredns.conf" << "EOF2"
g coredns 72
u coredns 72:72 "CoreDNS is a DNS server that chains plugins" /var/lib/coredns /usr/bin/false
EOF2
    cat > "$DESTDIR/usr/lib/tmpfiles.d/coredns.conf" << "EOF2"
d /var/lib/coredns 0755 coredns coredns -
EOF2
}
