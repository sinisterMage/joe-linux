# Following the book's KDE Frameworks page (only KArchive is built; the
# book builds every framework in one loop with these flags).
build() {
    mkdir build
    cd build
    # Every compression library is required (the WITH_* switches default
    # to ON), so none can be picked up silently.
    cmake -D CMAKE_INSTALL_PREFIX=/usr \
        -D CMAKE_INSTALL_LIBEXECDIR=libexec \
        -D CMAKE_SKIP_INSTALL_RPATH=ON \
        -D CMAKE_BUILD_TYPE=Release \
        -D BUILD_TESTING=OFF \
        -D BUILD_PYTHON_BINDINGS=OFF \
        -D WITH_BZIP2=ON \
        -D WITH_LIBLZMA=ON \
        -D WITH_OPENSSL=ON \
        -D WITH_LIBZSTD=ON \
        -W no-author ..
    make
}

package() {
    cd build
    make DESTDIR="$DESTDIR" install
}
