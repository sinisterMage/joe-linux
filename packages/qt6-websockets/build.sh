# Not in the book as a module of its own: the book's Qt6 page builds
# qtwebsockets inside qt-everywhere. This builds the same release from the
# module's own tarball against the installed qt6, as other distributions do
# and as qt6-multimedia does; Qt's build internals put everything where qt6
# put its own modules. Nextcloud's desktop client needs it.
build() {
    cmake -B build -G Ninja \
        -D CMAKE_BUILD_TYPE=Release \
        -D CMAKE_INSTALL_PREFIX=/usr \
        -D QT_BUILD_EXAMPLES=OFF \
        -D QT_BUILD_TESTS=OFF \
        -D QT_GENERATE_SBOM=OFF
    ninja -C build -j"$JOBS"
}

package() {
    DESTDIR="$DESTDIR" ninja -C build install
    # As in qt6: the build directory recorded in .prl files.
    find "$DESTDIR/usr" -name '*.prl' -exec sed -i -e '/^QMAKE_PRL_BUILD_DIR/d' {} \;
}
