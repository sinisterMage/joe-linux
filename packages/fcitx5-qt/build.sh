# Not in the book: the newest upstream release, built with CMake as its
# README says.
build() {
    # Qt 6 only: joe packages neither Qt 5 nor Qt 4. The Qt 6 Wayland
    # workaround (input in native Wayland Qt windows) uses Qt Wayland's
    # private API, which joe's qt6 has.
    cmake -B build -G Ninja \
        -D CMAKE_INSTALL_PREFIX=/usr \
        -D CMAKE_INSTALL_LIBDIR=lib \
        -D CMAKE_INSTALL_LIBEXECDIR=libexec \
        -D CMAKE_BUILD_TYPE=Release \
        -D ENABLE_QT4=OFF \
        -D ENABLE_QT5=OFF \
        -D ENABLE_QT6=ON \
        -D ENABLE_X11=ON \
        -D ENABLE_QT6_WAYLAND_WORKAROUND=ON
    ninja -C build
}

package() {
    # The plugin goes to Qt's plugin directory, /usr/lib/qt6/plugins.
    DESTDIR="$DESTDIR" ninja -C build install
}
