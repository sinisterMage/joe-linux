# Not in the book: the newest upstream release, built as upstream's release
# workflow (.github/workflows/release-build.yml) and Dockerfile build it:
# the backend with "make build-go" and cgo off, the frontend with
# "yarn install --immutable" and "yarn build" from upstream's yarn.lock. It is
# laid out as upstream's own packages lay it out (scripts/build-rpm.sh,
# packaging/): the program and its assets in /usr/share/grafana, the
# configuration in /etc/grafana, the state in /var/lib/grafana.
#
# Left out: the data source plugins upstream's packages bundle in
# data/plugins-bundled (scripts/catalog-plugins-defaults: Prometheus, Loki,
# Elasticsearch, MySQL, PostgreSQL, InfluxDB, Tempo, Jaeger, Zipkin, ...).
# Since Grafana 13 they are not in this repository: "make build-targz"
# downloads them, prebuilt and signed, from the grafana.com catalog. The
# data sources built in here are Graphite, Azure Monitor, TestData,
# Alertmanager and Grafana's own; the others can be installed at run time
# from the catalog (grafana cli plugins install ID) into
# /var/lib/grafana/plugins.

go_env() {
    # Go's caches in the build directory, outside the source tree (nx and
    # yarn look for workspaces in it); never fetch another Go toolchain.
    export GOPATH=/build/go
    export GOMODCACHE=/build/go/pkg/mod
    export GOCACHE=/build/go/cache
    export GOTOOLCHAIN=local GOTELEMETRY=off
    export GOFLAGS="-mod=readonly -trimpath -buildmode=pie -modcacherw"
    export CGO_ENABLED=0
}

yarn_env() {
    # Yarn 4 is committed with the source (.yarnrc.yml's yarnPath), and
    # nodejs has no corepack, so "yarn" is that file run by node. nx runs
    # the plugins' builds through it, so it must be on PATH.
    install -d /build/bin /build/home
    cat > /build/bin/yarn << EOF
#!/bin/sh
exec node "$PWD/.yarn/releases/yarn-4.18.1.cjs" "\$@"
EOF
    chmod 755 /build/bin/yarn
    export PATH="/build/bin:$PATH"
    # Yarn's package cache (enableGlobalCache) and anything a tool keeps in
    # its home go to the build directory, not to the shared build root's
    # /root. No telemetry, no Nx daemon or cloud cache.
    export HOME=/build/home
    export YARN_GLOBAL_FOLDER=/build/yarn
    export YARN_ENABLE_TELEMETRY=0 YARN_ENABLE_PROGRESS_BARS=false
    export NX_DAEMON=false NX_NO_CLOUD=true
}

build() {
    # The backend: the single grafana program (server and cli are its
    # subcommands), with the version stamps the release sets: the commit
    # the v13.3.1 tag points to and its time. "oss" are the Dockerfile's
    # build tags. The Wire graph and themes_generated.go are committed, so
    # nothing is generated first.
    go_env
    make build-go \
        GO_BUILD_TAGS=oss \
        COMMIT_SHA=5db6ba887630c7fa12e5bfd063f2fa854025468c \
        BUILD_BRANCH=HEAD \
        SOURCE_DATE_EPOCH=1794346235

    # The frontend, into public/build and public/build-swagger, and the
    # three plugins kept in this repository (Graphite, Azure Monitor,
    # TestData) into their dist directories. The yarnrc turns off install
    # scripts (only msw's runs, which copies its service worker into
    # public/). The bundlers (rspack, SWC, esbuild, Lightning CSS) and nx
    # are npm packages with prebuilt native binaries, run only here; what
    # is installed is built from source. Upstream asks for Node 22 to 24
    # (.nvmrc, engines), which yarn does not enforce; this is Node 26. The
    # build script gives node an 8 GiB heap.
    yarn_env
    yarn install --immutable
    yarn build
}

package() {
    local home=$DESTDIR/usr/share/grafana

    # What upstream's release archive holds (scripts/build-targz.sh): the
    # program, conf/ (defaults.ini, which must not be edited, sample.ini
    # and the provisioning samples), and public/ without the node_modules
    # directories yarn made in the plugin workspaces.
    install -Dm755 bin/linux/amd64/grafana "$home/bin/grafana"
    cp -r conf "$home/conf"
    cp -r public "$home/public"
    find "$home/public" -type d -name node_modules -prune -exec rm -rf {} +
    install -m644 LICENSE NOTICE.md "$home/"
    echo "$PKG_VERSION" > "$home/VERSION"

    # Upstream's wrappers (in /usr/sbin in its packages): grafana passes
    # the packaged paths to "grafana server" and "grafana cli", the other
    # two are the deprecated old names. The completion is urfave/cli's for
    # bash; the zsh one is not written as an autoloaded function.
    install -d "$DESTDIR/usr/bin"
    install -m755 packaging/wrappers/grafana packaging/wrappers/grafana-server \
        packaging/wrappers/grafana-cli "$DESTDIR/usr/bin/"
    install -Dm644 packaging/autocomplete/bash_autocomplete \
        "$DESTDIR/usr/share/bash-completion/completions/grafana"

    # The configuration upstream's packages copy into place when first
    # installed (packaging/rpm/control/postinst): sample.ini, with every
    # setting commented out, as grafana.ini, the LDAP example, and the
    # provisioning samples. grafana.ini and ldap.toml hold secrets, so
    # tmpfiles.d below makes them readable by the grafana group only, as
    # upstream's postinst does.
    install -Dm644 conf/sample.ini "$DESTDIR/etc/grafana/grafana.ini"
    install -m644 conf/ldap.toml "$DESTDIR/etc/grafana/ldap.toml"
    local dir
    for dir in dashboards datasources plugins access-control alerting; do
        install -Dm644 "conf/provisioning/$dir/sample.yaml" \
            "$DESTDIR/etc/grafana/provisioning/$dir/sample.yaml"
    done

    # Upstream's unit (packaging/rpm/systemd/grafana-server.service), with
    # the values of its EnvironmentFile (/etc/sysconfig/grafana-server)
    # written in and without --packaging=rpm, which only labels the usage
    # statistics. Not enabled.
    install -d "$DESTDIR/usr/lib/systemd/system"
    cat > "$DESTDIR/usr/lib/systemd/system/grafana-server.service" << "EOF"
[Unit]
Description=Grafana instance
Documentation=http://docs.grafana.org
Wants=network-online.target
After=network-online.target
After=postgresql.service mariadb.service mysqld.service influxdb.service

[Service]
User=grafana
Group=grafana
Type=notify
Restart=on-failure
WorkingDirectory=/usr/share/grafana
RuntimeDirectory=grafana
RuntimeDirectoryMode=0750
Environment=PLUGIN_UNIX_SOCKET_DIR=/run/grafana
ExecStart=/usr/share/grafana/bin/grafana server \
                            --config=/etc/grafana/grafana.ini \
                            --pidfile=/run/grafana/grafana-server.pid \
                            cfg:default.paths.logs=/var/log/grafana \
                            cfg:default.paths.data=/var/lib/grafana \
                            cfg:default.paths.plugins=/var/lib/grafana/plugins \
                            cfg:default.paths.provisioning=/etc/grafana/provisioning \
                            cfg:default.paths.bundled_plugins=/var/lib/grafana/plugins-bundled

LimitNOFILE=10000
TimeoutStopSec=20
CapabilityBoundingSet=
DeviceAllow=
LockPersonality=true
MemoryDenyWriteExecute=false
NoNewPrivileges=true
PrivateDevices=true
PrivateTmp=true
ProtectClock=true
ProtectControlGroups=true
ProtectHome=true
ProtectHostname=true
ProtectKernelLogs=true
ProtectKernelModules=true
ProtectKernelTunables=true
ProtectProc=invisible
ProtectSystem=full
RemoveIPC=true
RestrictAddressFamilies=AF_INET AF_INET6 AF_UNIX
RestrictNamespaces=true
RestrictRealtime=true
RestrictSUIDSGID=true
SystemCallArchitectures=native
UMask=0027

[Install]
WantedBy=multi-user.target
EOF

    # The account the server runs as, with a fixed id. Its home is the data
    # directory, which every deployment shares (upstream uses
    # /usr/share/grafana, which is read-only here; the AWS SDK keeps
    # credentials in ~/.aws).
    install -d "$DESTDIR/usr/lib/sysusers.d" "$DESTDIR/usr/lib/tmpfiles.d"
    cat > "$DESTDIR/usr/lib/sysusers.d/grafana.conf" << "EOF"
g grafana 68
u grafana 68:68 "Grafana" /var/lib/grafana /usr/bin/false
EOF
    cat > "$DESTDIR/usr/lib/tmpfiles.d/grafana.conf" << "EOF"
d /var/lib/grafana 0750 grafana grafana -
d /var/lib/grafana/plugins 0750 grafana grafana -
d /var/log/grafana 0750 grafana grafana -
z /etc/grafana/grafana.ini 0640 root grafana -
z /etc/grafana/ldap.toml 0640 root grafana -
EOF
}
