# Following the book's Qt6 module build, from the matching module tarball.
# Installed Qt BuildInternals supplies the same layout as packages/qt6.
# GeoClue2 uses Qt DBus; NMEA TCP/file and serial-port input are enabled.
# Gypsy is obsolete and disabled.
build() {
    cmake -S . -B build -G Ninja \
        -D CMAKE_BUILD_TYPE=Release \
        -D CMAKE_INSTALL_PREFIX=/usr \
        -D CMAKE_INSTALL_LIBDIR=lib \
        -D QT_BUILD_EXAMPLES=OFF -D QT_BUILD_TESTS=OFF \
        -D QT_GENERATE_SBOM=OFF \
        -D FEATURE_gypsy=OFF
    ninja -C build -j"$JOBS"
}

package() {
    DESTDIR="$DESTDIR" ninja -C build install
    find "$DESTDIR/usr" -name '*.prl' -exec sed -i '/^QMAKE_PRL_BUILD_DIR/d' {} \;
}
