# Following the book's SVT-AV1 page. The encoder application is built
# (BUILD_APPS defaults to on); the tests are not. EXCLUDE_HASH: the archive
# is not a git checkout, and it keeps the build reproducible.
build() {
    mkdir build
    cd build
    cmake -D CMAKE_INSTALL_PREFIX=/usr \
        -D CMAKE_INSTALL_LIBDIR=lib \
        -D CMAKE_BUILD_TYPE=Release \
        -D CMAKE_SKIP_INSTALL_RPATH=ON \
        -D BUILD_SHARED_LIBS=ON \
        -D BUILD_APPS=ON \
        -D BUILD_TESTING=OFF \
        -D EXCLUDE_HASH=ON \
        -W no-author -G Ninja ..
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
