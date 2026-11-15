build() {
    mkdir build
    cd build
    # The book's options. The crypto providers are stated rather than
    # whatever the build root has (USE_IMPLICIT_CRYPTO): both OpenSSL and
    # GnuTLS, which is what the book's build picks up on a system with both.
    # The manual would need Sphinx; the examples go to the documentation
    # directory, which is not shipped.
    cmake -D CMAKE_INSTALL_PREFIX=/usr \
        -D CMAKE_INSTALL_LIBDIR=lib \
        -D CMAKE_BUILD_TYPE=Release \
        -D BUILD_STATIC_LIBS=OFF \
        -D CMAKE_INSTALL_DOCDIR=/usr/share/doc/qpdf-12.4.2 \
        -D USE_IMPLICIT_CRYPTO=OFF \
        -D REQUIRE_CRYPTO_OPENSSL=ON \
        -D REQUIRE_CRYPTO_GNUTLS=ON \
        -D BUILD_DOC=OFF \
        ..
    make
}

package() {
    cd build
    make DESTDIR="$DESTDIR" install
}
