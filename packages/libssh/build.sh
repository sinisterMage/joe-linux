# Not in the book: the newest upstream release, built as its INSTALL says.
build() {
    mkdir build
    cd build
    # OpenSSL is the cryptographic backend (the default). Kerberos
    # (GSSAPI), compression, SFTP and the server side are on.
    # Off: libnacl and libfido2 (no recipes; OpenSSL provides curve25519),
    # the example programs, and the Doxygen reference.
    cmake -D CMAKE_INSTALL_PREFIX=/usr \
        -D CMAKE_INSTALL_LIBDIR=lib \
        -D CMAKE_BUILD_TYPE=Release \
        -D WITH_GSSAPI=ON \
        -D WITH_ZLIB=ON \
        -D WITH_SFTP=ON \
        -D WITH_SERVER=ON \
        -D WITH_NACL=OFF \
        -D WITH_FIDO2=OFF \
        -D WITH_EXAMPLES=OFF \
        -D UNIT_TESTING=OFF \
        -D CMAKE_DISABLE_FIND_PACKAGE_Doxygen=ON \
        -G Ninja ..
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
