# Not in the book: the newest upstream release (2.0 is only a release
# candidate), built with CMake as its README describes. Upstream publishes
# no checksum for the archive.
build() {
    mkdir build
    cd build
    # System OpenSSL, libssh2, krb5 (GSSAPI), pcre2 and zlib. The HTTP
    # parser (llhttp), xdiff and the NTLM client have no recipes and come
    # from the bundled copies. SHA-1 uses the collision-detecting
    # implementation, SHA-256 OpenSSL. The experimental git2 command-line
    # program is not built, nor are the tests.
    cmake -D CMAKE_INSTALL_PREFIX=/usr \
        -D CMAKE_INSTALL_LIBDIR=lib \
        -D CMAKE_BUILD_TYPE=Release \
        -D BUILD_SHARED_LIBS=ON \
        -D BUILD_TESTS=OFF \
        -D BUILD_CLI=OFF \
        -D BUILD_EXAMPLES=OFF \
        -D BUILD_FUZZERS=OFF \
        -D USE_HTTPS=OpenSSL \
        -D USE_SHA1=CollisionDetection \
        -D USE_SHA256=HTTPS \
        -D USE_SSH=libssh2 \
        -D USE_GSSAPI=gssapi \
        -D USE_NTLMCLIENT=ON \
        -D USE_HTTP_PARSER=builtin \
        -D REGEX_BACKEND=pcre2 \
        -D USE_BUNDLED_ZLIB=OFF \
        -G Ninja ..
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
