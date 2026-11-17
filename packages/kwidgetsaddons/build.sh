# Following BLFS's KDE Frameworks 6.29.0 page, building only this Qt-only leaf.
build() {
    cmake -B build -G Ninja \
        -D CMAKE_INSTALL_PREFIX=/usr \
        -D CMAKE_INSTALL_LIBDIR=lib \
        -D CMAKE_INSTALL_LIBEXECDIR=libexec \
        -D CMAKE_BUILD_TYPE=Release \
        -D CMAKE_SKIP_INSTALL_RPATH=ON \
        -D BUILD_SHARED_LIBS=ON \
        -D BUILD_TESTING=OFF \
        -D BUILD_PYTHON_BINDINGS=OFF \
        -D BUILD_DESIGNERPLUGIN=OFF \
        -D BUILD_QCH=OFF \
        -D BUILD_QDOC=OFF
    cmake --build build
}

package() {
    DESTDIR="$DESTDIR" cmake --install build
}
