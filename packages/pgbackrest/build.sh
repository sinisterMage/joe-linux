# Not in the book: the newest upstream release, built as its README says.
prepare() {
    # Backtraces in error reports use libbacktrace when meson finds it; no
    # option turns that off, and libbacktrace is not packaged, so the
    # detection is removed rather than left to the build root.
    sed -i "s/^lib_backtrace = cc.find_library('backtrace'.*/lib_backtrace = dependency('', required: false)/" meson.build
    grep -q "^lib_backtrace = dependency('', required: false)$" meson.build
}

build() {
    # SFTP storage (libssh2), zstd compression and systemd notification
    # stated on rather than left to detection.
    meson setup build \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        -D configdir=/etc/pgbackrest \
        -D libssh2=enabled \
        -D libzstd=enabled \
        -D libsystemd=enabled
    ninja -C build
}

package() {
    DESTDIR="$DESTDIR" ninja -C build install

    # A configuration with the default paths spelled out; the administrator
    # adds a section for each stanza.
    install -d "$DESTDIR/etc/pgbackrest"
    cat > "$DESTDIR/etc/pgbackrest/pgbackrest.conf" << "EOF2"
# pgBackRest configuration: see "pgbackrest help" and
# https://pgbackrest.org/configuration.html. Add a section per stanza, e.g.
#
# [main]
# pg1-path=/var/lib/postgres/data

[global]
repo1-path=/var/lib/pgbackrest
log-path=/var/log/pgbackrest
spool-path=/var/spool/pgbackrest
EOF2

    # The repository, log and spool directories pgbackrest uses by default,
    # owned by the postgres account (from the postgresql package). The lock
    # directory (/tmp/pgbackrest) pgbackrest creates itself.
    install -d "$DESTDIR/usr/lib/tmpfiles.d"
    cat > "$DESTDIR/usr/lib/tmpfiles.d/pgbackrest.conf" << "EOF2"
d /var/lib/pgbackrest 0750 postgres postgres -
d /var/log/pgbackrest 0770 postgres postgres -
d /var/spool/pgbackrest 0750 postgres postgres -
EOF2
}
