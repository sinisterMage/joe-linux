# Not in the book: the newest upstream release, built with CMake as its
# INSTALL.md describes.
build() {
    mkdir build
    cd build
    # Every compression method; OpenSSL rather than GnuTLS for encryption.
    # The tools are built, the tests, fuzzers and examples are not.
    # DOCUMENTATION_FORMAT=man installs the manual pages already formatted
    # in the tarball, whichever of mandoc, groff and nroff is around.
    cmake -D CMAKE_INSTALL_PREFIX=/usr \
        -D CMAKE_INSTALL_LIBDIR=lib \
        -D CMAKE_BUILD_TYPE=Release \
        -D ENABLE_BZIP2=ON \
        -D ENABLE_LZMA=ON \
        -D ENABLE_ZSTD=ON \
        -D ENABLE_OPENSSL=ON \
        -D ENABLE_GNUTLS=OFF \
        -D ENABLE_COMMONCRYPTO=OFF \
        -D ENABLE_WINDOWS_CRYPTO=OFF \
        -D BUILD_TOOLS=ON \
        -D BUILD_REGRESS=OFF \
        -D BUILD_OSSFUZZ=OFF \
        -D BUILD_EXAMPLES=OFF \
        -D BUILD_DOC=ON \
        -D DOCUMENTATION_FORMAT=man \
        -G Ninja ..
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
