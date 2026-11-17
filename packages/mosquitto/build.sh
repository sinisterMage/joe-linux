# Not in the book: the newest upstream release, built with CMake as its
# README-compiling.md says.
build() {
    # Upstream's defaults (TLS, WebSockets through the built-in
    # implementation, bridges, persistence, the plugins), plus systemd
    # notification, which upstream's mosquitto.service.notify needs. The
    # HTTP API listener is built because libmicrohttpd is there; it has no
    # default directory (HTTP_API_DIR): the dashboard in the source tree is
    # not built (it needs Tailwind), so listeners name their http_dir.
    # Off: the example plugins, tests, SRV lookups (c-ares, off by
    # default), getaddrinfo_a and tcp-wrappers. The manual pages ship
    # ready-made.
    cmake -B build -G Ninja \
        -D CMAKE_BUILD_TYPE=Release \
        -D CMAKE_INSTALL_PREFIX=/usr \
        -D CMAKE_INSTALL_LIBDIR=lib \
        -D CMAKE_INSTALL_SYSCONFDIR=/etc \
        -D WITH_BUNDLED_DEPS=ON \
        -D WITH_TLS=ON \
        -D WITH_TLS_PSK=ON \
        -D WITH_WEBSOCKETS=ON \
        -D WITH_WEBSOCKETS_BUILTIN=ON \
        -D WITH_SYSTEMD=ON \
        -D WITH_HTTP_API=ON \
        -D HTTP_API_DIR= \
        -D WITH_CTRL_SHELL=ON \
        -D WITH_PLUGIN_PERSIST_SQLITE=ON \
        -D WITH_PLUGIN_EXAMPLES=OFF \
        -D WITH_SRV=OFF \
        -D WITH_ADNS=OFF \
        -D USE_LIBWRAP=OFF \
        -D WITH_DLT=OFF \
        -D WITH_TESTS=OFF \
        -D WITH_STATIC_LIBRARIES=OFF
    cmake --build build
}

package() {
    DESTDIR="$DESTDIR" cmake --install build

    # make install puts upstream's annotated configuration, every option
    # commented out, in /etc/mosquitto as mosquitto.conf.example; the
    # unit reads mosquitto.conf, so it is installed under that name too.
    # Without a listener the broker serves localhost only.
    install -m644 mosquitto.conf "$DESTDIR/etc/mosquitto/mosquitto.conf"

    # Upstream's notify unit (service/systemd/mosquitto.service.notify). It
    # makes /run/mosquitto and /var/log/mosquitto itself. Not enabled.
    install -Dm644 service/systemd/mosquitto.service.notify \
        "$DESTDIR/usr/lib/systemd/system/mosquitto.service"

    # The account the broker runs as. Its home holds the persistence
    # database when persistence_location points there.
    install -d "$DESTDIR/usr/lib/sysusers.d" "$DESTDIR/usr/lib/tmpfiles.d"
    cat > "$DESTDIR/usr/lib/sysusers.d/mosquitto.conf" << "EOT"
g mosquitto 39
u mosquitto 39:39 "Mosquitto MQTT broker" /var/lib/mosquitto /usr/bin/false
EOT
    cat > "$DESTDIR/usr/lib/tmpfiles.d/mosquitto.conf" << "EOT"
d /var/lib/mosquitto 0700 mosquitto mosquitto -
EOT
}
