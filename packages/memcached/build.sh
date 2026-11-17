# Not in the book: the newest upstream release, built as its README says.
build() {
    # TLS (OpenSSL), SASL authentication (Cyrus SASL, -S) and the seccomp
    # filters, which are applied only when memcached is started with
    # "-o drop_privileges". Off: the experimental proxy (it builds a
    # bundled Lua) and regenerating the protocol specifications (xml2rfc);
    # the manual page ships ready-made.
    ./configure --prefix=/usr \
        --enable-tls \
        --enable-seccomp \
        --enable-sasl \
        --disable-proxy \
        --disable-docs \
        --disable-werror \
        --disable-dtrace
    make
}

package() {
    make DESTDIR="$DESTDIR" install

    # Upstream's helper for inspecting a running server, with its manual
    # page; make install leaves it out.
    install -Dm755 scripts/memcached-tool "$DESTDIR/usr/bin/memcached-tool"
    install -Dm644 scripts/memcached-tool.1 "$DESTDIR/usr/share/man/man1/memcached-tool.1"

    # Upstream's units (scripts/), with the hardening its RPM spec turns on
    # (the ##safer## lines). They read their settings from
    # /etc/sysconfig/memcached, a Red Hat path; here that file is
    # /etc/memcached.conf: upstream's memcached.sysconfig, running memcached
    # as its own account rather than nobody. memcached@PORT.service also
    # reads /etc/memcached.conf.PORT if it exists. Neither unit is enabled.
    install -d "$DESTDIR/usr/lib/systemd/system"
    local unit
    for unit in memcached.service memcached@.service; do
        sed -e 's/^##safer##//' \
            -e 's@/etc/sysconfig/memcached@/etc/memcached.conf@' \
            "scripts/$unit" > "$DESTDIR/usr/lib/systemd/system/$unit"
    done
    install -d "$DESTDIR/etc"
    sed -e 's/^USER=.*/USER="memcached"/' \
        -e 's@/etc/sysconfig/memcached@/etc/memcached.conf@' \
        scripts/memcached.sysconfig > "$DESTDIR/etc/memcached.conf"

    # The account memcached drops to (-u). It keeps nothing on disk.
    install -d "$DESTDIR/usr/lib/sysusers.d"
    cat > "$DESTDIR/usr/lib/sysusers.d/memcached.conf" << "EOF"
g memcached 37
u memcached 37:37 "memcached daemon" - /usr/bin/false
EOF
}
