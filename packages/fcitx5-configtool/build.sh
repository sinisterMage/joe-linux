# Not in the book: upstream 5.1.16, built as its CMakeLists.txt specifies.
# The user approved only KItemViews and KWidgetsAddons, two Qt-only leaves.
# Turning KCM off alone is insufficient: the standalone GUI requires both.
build() {
    cmake -B build -G Ninja \
        -D CMAKE_INSTALL_PREFIX=/usr \
        -D CMAKE_INSTALL_LIBDIR=lib \
        -D CMAKE_INSTALL_LIBEXECDIR=libexec \
        -D CMAKE_BUILD_TYPE=Release \
        -D CMAKE_SKIP_INSTALL_RPATH=ON \
        -D ENABLE_KCM=OFF \
        -D ENABLE_CONFIG_QT=ON \
        -D ENABLE_TEST=OFF \
        -D CMAKE_DISABLE_FIND_PACKAGE_KF6DBusAddons=ON \
        -D CMAKE_DISABLE_FIND_PACKAGE_KF6WindowSystem=ON
    cmake --build build
}

package() {
    DESTDIR="$DESTDIR" cmake --install build
}
