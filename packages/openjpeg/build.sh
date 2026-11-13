build() {
    mkdir build
    cd build
    # The book's options, plus:
    # - CMAKE_INSTALL_LIBDIR, so that nothing can pick lib64;
    # - BUILD_THIRDPARTY=OFF: the tools use the system's lcms2, libpng, tiff
    #   and zlib, never the copies in the tarball;
    # - no documentation, tests, JPIP, viewer or Java bindings.
    cmake -D CMAKE_BUILD_TYPE=Release \
        -D CMAKE_INSTALL_PREFIX=/usr \
        -D CMAKE_INSTALL_LIBDIR=lib \
        -D BUILD_SHARED_LIBS=ON \
        -D BUILD_STATIC_LIBS=OFF \
        -D BUILD_CODEC=ON \
        -D BUILD_THIRDPARTY=OFF \
        -D BUILD_DOC=OFF \
        -D BUILD_TESTING=OFF \
        -D BUILD_JPIP=OFF \
        -D BUILD_VIEWER=OFF \
        -D BUILD_JAVA=OFF \
        ..
    make
}

package() {
    cd build
    make DESTDIR="$DESTDIR" install
    # From the book: the manual pages are not installed by cmake.
    install -d "$DESTDIR/usr/share"
    cp -rv ../doc/man -T "$DESTDIR/usr/share/man"
}
