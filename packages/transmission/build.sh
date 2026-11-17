# Following the book's Transmission page.
prepare() {
    # The upstream CMake wrapper otherwise hard-codes its bundled headers.
    grep -Fq '${TR_THIRD_PARTY_SOURCE_DIR}/rapidjson/include' cmake/FindRapidJSON.cmake
    sed -i 's|${TR_THIRD_PARTY_SOURCE_DIR}/rapidjson/include|/usr/include|' cmake/FindRapidJSON.cmake
}

build() {
    # The book's recommended system libevent, libdeflate and libpsl are
    # used; dht, libb64, libnatpmp, libutp and miniupnpc have no recipes and
    # are built from the copies in third-party/ (linked statically), as are
    # the header-only fmt, utf8cpp, small and fast_float. RapidJSON comes
    # from the system headers. The
    # web client is installed from the prebuilt assets in the tarball
    # (rebuilding it needs npm and the network). The Qt client is left out
    # for the GTK 4 one; tray icons (appindicator) are GTK 3 only.
    # ENABLE_CLI adds the deprecated transmission-cli to the utilities
    # (transmission-remote, -create, -edit, -show).
    cmake -B build \
        -D CMAKE_INSTALL_PREFIX=/usr \
        -D CMAKE_INSTALL_LIBDIR=lib \
        -D CMAKE_BUILD_TYPE=Release \
        -D CMAKE_INSTALL_DOCDIR=/usr/share/doc/transmission-4.1.4 \
        -D ENABLE_DAEMON=ON \
        -D ENABLE_GTK=ON \
        -D USE_GTK_VERSION=4 \
        -D ENABLE_QT=OFF \
        -D ENABLE_MAC=OFF \
        -D ENABLE_UTILS=ON \
        -D ENABLE_CLI=ON \
        -D ENABLE_TESTS=OFF \
        -D ENABLE_UTP=ON \
        -D ENABLE_NLS=ON \
        -D INSTALL_DOC=ON \
        -D INSTALL_LIB=OFF \
        -D REBUILD_WEB=OFF \
        -D INSTALL_WEB=ON \
        -D RUN_CLANG_TIDY=OFF \
        -D WITH_CRYPTO=openssl \
        -D WITH_INOTIFY=ON \
        -D WITH_KQUEUE=OFF \
        -D WITH_APPINDICATOR=OFF \
        -D WITH_SYSTEMD=ON \
        -D USE_SYSTEM_EVENT2=ON \
        -D USE_SYSTEM_DEFLATE=ON \
        -D USE_SYSTEM_PSL=ON \
        -D USE_SYSTEM_DHT=OFF \
        -D USE_SYSTEM_MINIUPNPC=OFF \
        -D USE_SYSTEM_NATPMP=OFF \
        -D USE_SYSTEM_UTP=OFF \
        -D USE_SYSTEM_B64=OFF
    # The bundled libraries are ExternalProjects that install into the build
    # tree; with the package's exported DESTDIR they would land under it.
    env -u DESTDIR cmake --build build
}

package() {
    DESTDIR="$DESTDIR" cmake --install build

    install -d "$DESTDIR/usr/share/pixmaps"
    rsvg-convert \
        "$DESTDIR/usr/share/icons/hicolor/scalable/apps/transmission-gtk.svg" \
        -o "$DESTDIR/usr/share/pixmaps/transmission.png"

    # transmission-daemon.service (not enabled) runs the daemon as the
    # transmission account, whose home holds its settings and downloads
    # ($HOME/.config/transmission-daemon). Upstream ships no sysusers file.
    install -d "$DESTDIR/usr/lib/sysusers.d" "$DESTDIR/usr/lib/tmpfiles.d"
    cat > "$DESTDIR/usr/lib/sysusers.d/transmission.conf" << "EOT"
g transmission 96
u transmission 96:96 "Transmission BitTorrent daemon" /var/lib/transmission /usr/bin/false
EOT
    cat > "$DESTDIR/usr/lib/tmpfiles.d/transmission.conf" << "EOT"
d /var/lib/transmission 0750 transmission transmission -
EOT
}
