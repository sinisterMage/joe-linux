# Not in the book: the newest upstream release, built as .ci/ci-build.sh
# builds the Linux release binaries: the vendored modules, no cgo. The
# version is a constant in dnscrypt-proxy/main.go, so nothing is stamped.
prepare() {
    # The resolver lists are downloaded and cached at run time. Relative
    # paths are taken from the configuration's directory, /etc, which the
    # service cannot write to (and whose files are not its to change); keep
    # them in /var/cache/dnscrypt-proxy, the unit's CacheDirectory, as Arch
    # Linux does.
    sed -E -i "s#(cache_file = )(['\"])([^/'\"]+)(['\"])#\1\2/var/cache/dnscrypt-proxy/\3\4#" \
        dnscrypt-proxy/example-dnscrypt-proxy.toml
    grep -q "^cache_file = '/var/cache/dnscrypt-proxy/public-resolvers.md'" \
        dnscrypt-proxy/example-dnscrypt-proxy.toml
}

build() {
    # Go's build cache inside the build directory, out of the shared build
    # root's /root; never fetch another Go toolchain.
    export GOPATH="$PWD/.gopath"
    export GOCACHE="$PWD/.gocache"
    export GOTOOLCHAIN=local GOTELEMETRY=off
    export GOFLAGS="-mod=vendor -trimpath -buildmode=pie"
    export CGO_ENABLED=0
    cd dnscrypt-proxy
    go build -ldflags "-s -w" -o dnscrypt-proxy .
}

package() {
    install -Dm755 dnscrypt-proxy/dnscrypt-proxy "$DESTDIR/usr/bin/dnscrypt-proxy"

    # Upstream's annotated example as the configuration: it listens on
    # 127.0.0.1:53 (systemd-resolved's stub is on 127.0.0.53) and picks
    # resolvers from the public list. The example rule files it refers to
    # are kept beside it under their upstream names, for copying. The
    # demonstration key upstream ships for a local DoH server
    # (localhost.pem) is left out.
    install -Dm644 dnscrypt-proxy/example-dnscrypt-proxy.toml "$DESTDIR/etc/dnscrypt-proxy/dnscrypt-proxy.toml"
    install -d "$DESTDIR/usr/share/dnscrypt-proxy"
    install -m644 dnscrypt-proxy/example-*.txt "$DESTDIR/usr/share/dnscrypt-proxy/"

    # Upstream ships no unit (dnscrypt-proxy -service install writes one);
    # this is Arch Linux's, without socket activation: a transient account
    # (DynamicUser), so no fixed id is needed. Not enabled.
    install -d "$DESTDIR/usr/lib/systemd/system"
    cat > "$DESTDIR/usr/lib/systemd/system/dnscrypt-proxy.service" << "EOF2"
[Unit]
Description=DNSCrypt-proxy client
Documentation=https://github.com/DNSCrypt/dnscrypt-proxy/wiki
Wants=network-online.target nss-lookup.target
Before=nss-lookup.target

[Service]
AmbientCapabilities=CAP_NET_BIND_SERVICE
CacheDirectory=dnscrypt-proxy
CapabilityBoundingSet=CAP_NET_BIND_SERVICE
DynamicUser=yes
ExecStart=/usr/bin/dnscrypt-proxy --config /etc/dnscrypt-proxy/dnscrypt-proxy.toml
LockPersonality=yes
LogsDirectory=dnscrypt-proxy
MemoryDenyWriteExecute=true
NoNewPrivileges=true
PrivateDevices=true
ProtectControlGroups=yes
ProtectHome=yes
ProtectHostname=yes
ProtectKernelLogs=yes
ProtectKernelModules=yes
ProtectKernelTunables=yes
ProtectSystem=strict
RestrictAddressFamilies=AF_INET AF_INET6
RestrictNamespaces=true
RestrictRealtime=true
RuntimeDirectory=dnscrypt-proxy
StateDirectory=dnscrypt-proxy
SystemCallArchitectures=native
SystemCallFilter=@system-service

[Install]
WantedBy=multi-user.target
EOF2
}
