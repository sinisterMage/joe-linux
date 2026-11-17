# Not in the book: the newest upstream release, built with CMake as
# upstream's own RPM (netdata.spec.in) builds it.
#
# Licences. The agent is free software (GPL-3.0-or-later), but its web
# dashboard is not: since 2.2.0 the only dashboard netdata ships is the
# Netdata Cloud UI, licensed under the Netdata Cloud UI License (NCUL1),
# which CMake downloads from app.netdata.cloud/agent.tar.gz while
# configuring. It is left out (ENABLE_DASHBOARD=Off). The old free (GPL)
# dashboard was removed upstream in 2.2.0 and its repository
# (netdata/dashboard) is archived, so there is no free one to install in
# its place: this netdata serves its API (/api/v1, v2, v3), including the
# Prometheus exposition at /api/v1/allmetrics?format=prometheus, streaming
# to other agents, alerts and exporting, but no web pages. Also left out:
# the IBM collectors (ENABLE_PLUGIN_IBM), which need IBM's proprietary MQ
# client, and Sentry crash reporting.
#
# Telemetry: the agent sends anonymous statistics to netdata unless
# /etc/netdata/.opt-out-from-anonymous-statistics exists; there is no build
# option for it, so package() ships that file. Netdata Cloud is only
# contacted once an administrator claims the agent.

prepare() {
    # The SQLite source tree comes from $SOURCES instead of www.sqlite.org
    # (the SHA-256 that CMake checks stays the same).
    grep -q 'URL "https://www.sqlite.org/${SQLITE_VERSION_YEAR}/sqlite-src-${SQLITE_VERSION_NUMBER}.zip"' \
        packaging/cmake/Modules/NetdataSQLite.cmake
    sed -i "s|URL \"https://www.sqlite.org/\${SQLITE_VERSION_YEAR}/sqlite-src-\${SQLITE_VERSION_NUMBER}.zip\"|URL \"$SOURCES/sqlite-src-3530400.zip\"|" \
        packaging/cmake/Modules/NetdataSQLite.cmake
    grep -q "URL \"$SOURCES/sqlite-src-3530400.zip\"" packaging/cmake/Modules/NetdataSQLite.cmake

    # dlib, which CMake would otherwise clone with git.
    mkdir .deps
    tar -xf "$SOURCES/dlib-19.24.8.tar.gz" -C .deps
}

build() {
    # Keep Go's module and build caches inside the build directory, out of
    # the shared build root's /root; never fetch another Go toolchain. The
    # Go collectors are built without cgo (upstream's add_go_target), so
    # they link no library.
    export GOPATH="$PWD/.gopath"
    export GOMODCACHE="$PWD/.gopath/pkg/mod"
    export GOCACHE="$PWD/.gocache"
    export GOTOOLCHAIN=local GOTELEMETRY=off
    export GOFLAGS="-mod=readonly -trimpath -buildmode=pie -modcacherw"

    # Every optional part is stated, so the result does not depend on what
    # the build root holds. On: the collectors in C (apps, cgroups and
    # cgroup-network, debugfs, perf, slabinfo, local-listeners,
    # network-viewer, the systemd journal and units plugins, cups), the
    # Go, scripts (Nagios-compatible checks), python.d and charts.d
    # plugins, the MCP bridge, machine learning with dlib, and the system
    # JSON-C, LibYAML and Protocol Buffers. Stack traces in logs use
    # libunwind, since libbacktrace would be cloned from git at an
    # unpinned revision.
    #
    # Off because what they need has no recipe: IPMI (FreeIPMI), NFACCT
    # (libnetfilter_acct), Xen (xenstat), exporting to MongoDB
    # (mongo-c-driver) and Prometheus remote write (snappy). eBPF is off:
    # it builds netdata's fork of libbpf from git and downloads prebuilt
    # BPF objects. The OpenTelemetry and NetFlow plugins and the Rust
    # journal reader are off: they are Rust crates built through Corrosion,
    # cloned from git while configuring, and they compile their own copies
    # of AWS-LC, zstd and lz4. WebRTC is experimental and clones
    # libdatachannel. The experimental Go statsd plugin is off (the agent
    # has its own statsd server). jemalloc and mimalloc have no recipe, and
    # mold is not used even if present.
    cmake -B build -G Ninja \
        -D CMAKE_INSTALL_PREFIX=/ \
        -D CMAKE_BUILD_TYPE=Release \
        -D USE_MOLD=Off \
        -D ENABLE_DASHBOARD=Off \
        -D ENABLE_DBENGINE=On \
        -D ENABLE_ML=On \
        -D FETCHCONTENT_SOURCE_DIR_DLIB="$PWD/.deps/dlib-19.24.8" \
        -D ENABLE_PLUGIN_GO=On \
        -D ENABLE_ND_MCP=On \
        -D ENABLE_PLUGIN_SCRIPTS=On \
        -D ENABLE_PLUGIN_STATSD=Off \
        -D ENABLE_CGROUP_NAME=On \
        -D ENABLE_PLUGIN_PYTHON=On \
        -D ENABLE_PLUGIN_CHARTS=On \
        -D ENABLE_PLUGIN_APPS=On \
        -D ENABLE_PLUGIN_CGROUP_NETWORK=On \
        -D ENABLE_PLUGIN_DEBUGFS=On \
        -D ENABLE_PLUGIN_LOCAL_LISTENERS=On \
        -D ENABLE_PLUGIN_NETWORK_VIEWER=On \
        -D ENABLE_PLUGIN_PERF=On \
        -D ENABLE_PLUGIN_SLABINFO=On \
        -D ENABLE_PLUGIN_SYSTEMD_JOURNAL=On \
        -D ENABLE_PLUGIN_SYSTEMD_UNITS=On \
        -D ENABLE_PLUGIN_CUPS=On \
        -D ENABLE_PLUGIN_FREEIPMI=Off \
        -D ENABLE_PLUGIN_NFACCT=Off \
        -D ENABLE_PLUGIN_XENSTAT=Off \
        -D ENABLE_PLUGIN_EBPF=Off \
        -D ENABLE_PLUGIN_OTEL=Off \
        -D ENABLE_PLUGIN_NETFLOW=Off \
        -D ENABLE_NETDATA_JOURNAL_FILE_READER=Off \
        -D ENABLE_PLUGIN_IBM=Off \
        -D ENABLE_EXPORTER_PROMETHEUS_REMOTE_WRITE=Off \
        -D ENABLE_EXPORTER_MONGODB=Off \
        -D ENABLE_BUNDLED_JSONC=Off \
        -D ENABLE_BUNDLED_YAML=Off \
        -D ENABLE_BUNDLED_PROTOBUF=Off \
        -D Protobuf_LIBRARY=/usr/lib/libprotobuf.so \
        -D ENABLE_WEBRTC=Off \
        -D ENABLE_SENTRY=Off \
        -D ENABLE_LIBBACKTRACE=Off \
        -D ENABLE_LIBUNWIND=On \
        -D ENABLE_JEMALLOC=Off \
        -D ENABLE_MIMALLOC=Off
    ninja -C build
}

package() {
    DESTDIR="$DESTDIR" ninja -C build install

    local plugins=$DESTDIR/usr/libexec/netdata/plugins.d

    # Upstream's packages install these set-uid root, executable by the
    # netdata group only (4750 root:netdata): cgroup-network (enters
    # containers' network namespaces), local-listeners and
    # network-viewer.plugin (read every process's sockets) and ndsudo (runs
    # a fixed list of commands, such as smartctl and nvme, for the Go
    # collectors). Files are packaged root-owned, so the group is given at
    # boot by tmpfiles.d below.
    chmod 4750 "$plugins/cgroup-network" "$plugins/local-listeners" \
        "$plugins/network-viewer.plugin" "$plugins/ndsudo"

    # Upstream gives these file capabilities instead (setcap), which joe
    # cannot set, so they run with the netdata account's rights only:
    # apps.plugin (cap_dac_read_search, cap_sys_ptrace: without them it
    # cannot read other users' processes' I/O and open files),
    # debugfs.plugin (cap_dac_read_search, cap_audit_control),
    # perf.plugin (cap_perfmon: needs kernel.perf_event_paranoid lowered
    # instead), slabinfo.plugin (cap_dac_read_search: /proc/slabinfo is
    # root's) and go.d.plugin (cap_net_raw and others: ping uses the
    # unprivileged ICMP sockets systemd allows, privileged commands go
    # through ndsudo). systemd-journal.plugin needs cap_dac_read_search only
    # to read the journal, which membership of systemd-journal gives
    # (sysusers.d below).

    # The package manager, not netdata-updater, replaces netdata.
    rm "$DESTDIR/usr/libexec/netdata/netdata-updater.sh" \
        "$DESTDIR/usr/lib/netdata/system/cron/netdata-updater-daily" \
        "$DESTDIR/usr/lib/netdata/system/systemd/netdata-updater.service" \
        "$DESTDIR/usr/lib/netdata/system/systemd/netdata-updater.timer" \
        "$DESTDIR/usr/lib/netdata/conf.d/netdata-updater.conf"

    # No anonymous statistics (see the top of this file). Deleting this
    # file turns them on.
    : > "$DESTDIR/etc/netdata/.opt-out-from-anonymous-statistics"

    # Byte code for the python.d modules, which the netdata account cannot
    # write next to them.
    python3 -m compileall -q -s "$DESTDIR" -p / "$DESTDIR/usr/libexec/netdata/python.d"

    # Upstream's unit, as its RPM installs it: netdata starts as root and
    # drops to the netdata account, logging to its own journal namespace.
    # Not enabled.
    install -Dm644 build/system/systemd/netdata.service \
        "$DESTDIR/usr/lib/systemd/system/netdata.service"
    install -Dm644 system/systemd/journald@netdata.conf \
        "$DESTDIR/usr/lib/systemd/journald@netdata.conf.d/netdata.conf"

    # The account, with a fixed id instead of upstream's "-", allowed to
    # read the system journal. Upstream's tmpfiles.d file makes the cache,
    # state and log directories; the last lines give the set-uid helpers
    # their group.
    install -d "$DESTDIR/usr/lib/sysusers.d" "$DESTDIR/usr/lib/tmpfiles.d"
    cat > "$DESTDIR/usr/lib/sysusers.d/netdata.conf" << "EOF"
g netdata 94
u netdata 94:94 "Netdata Agent" /var/lib/netdata /usr/bin/false
m netdata systemd-journal
EOF
    install -m644 build/system/systemd/tmpfiles/netdata.conf "$DESTDIR/usr/lib/tmpfiles.d/netdata.conf"
    cat >> "$DESTDIR/usr/lib/tmpfiles.d/netdata.conf" << "EOF"

z /usr/libexec/netdata/plugins.d/cgroup-network 4750 root netdata -
z /usr/libexec/netdata/plugins.d/local-listeners 4750 root netdata -
z /usr/libexec/netdata/plugins.d/network-viewer.plugin 4750 root netdata -
z /usr/libexec/netdata/plugins.d/ndsudo 4750 root netdata -
EOF
}
