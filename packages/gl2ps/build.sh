# Not in the book: latest upstream stable with CMake.
# GLUT is only for demonstration programs; exclude those rather than adding a GUI toolkit.
build() {
    cmake -S . -B build -G Ninja \
        -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr \
        -DCMAKE_INSTALL_LIBDIR=lib \
        -DBUILD_SHARED_LIBS=ON -DENABLE_ZLIB=ON -DENABLE_PNG=ON \
        -DCMAKE_DISABLE_FIND_PACKAGE_GLUT=ON -DLIB_SUFFIX=
    cmake --build build -j"$JOBS"
}

package() {
    DESTDIR="$DESTDIR" cmake --install build
}
