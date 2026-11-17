# Not in the book: the newest upstream release, built as its INSTALL.txt says.
build() {
    # The Qt 6 library only, without its examples; the .pri file for qmake
    # users goes beside Qt's own (joe's Qt keeps its mkspecs in
    # /usr/lib/qt6). No rpath: the library is in /usr/lib.
    cmake -B build \
        -D CMAKE_INSTALL_PREFIX=/usr \
        -D CMAKE_INSTALL_LIBDIR=lib \
        -D CMAKE_BUILD_TYPE=Release \
        -D CMAKE_SKIP_INSTALL_RPATH=ON \
        -D KDSingleApplication_QT6=ON \
        -D KDSingleApplication_STATIC=OFF \
        -D KDSingleApplication_TESTS=OFF \
        -D KDSingleApplication_EXAMPLES=OFF \
        -D KDSingleApplication_DOCS=OFF \
        -D ECM_MKSPECS_INSTALL_DIR=/usr/lib/qt6/mkspecs/modules
    cmake --build build
}

package() {
    DESTDIR="$DESTDIR" cmake --install build
}
