# Not in the book: the newest upstream release, built with CMake as its
# README says.
build() {
    mkdir build
    cd build
    # TLS with GnuTLS and cryptography with libgcrypt, upstream's first
    # choices; OpenSSL would only be a fallback for both, so it is not
    # linked. zlib, LZO, libjpeg-turbo and libpng give the compressed
    # encodings; libsystemd socket activation.
    # Off: SASL (Cyrus SASL has no recipe), and the example programs and
    # tests, which are all that SDL, GTK, Qt, FFmpeg, XCB and libsshtunnel
    # would be used for.
    # CMakeLists.txt asks for a CMake older than 3.5, which CMake 4 no
    # longer accepts; the policies of 3.5 are what it was written for.
    cmake -D CMAKE_INSTALL_PREFIX=/usr \
        -D CMAKE_POLICY_VERSION_MINIMUM=3.5 \
        -D CMAKE_INSTALL_LIBDIR=lib \
        -D CMAKE_BUILD_TYPE=Release \
        -D WITH_ZLIB=ON \
        -D WITH_LZO=ON \
        -D WITH_JPEG=ON \
        -D WITH_PNG=ON \
        -D WITH_GNUTLS=ON \
        -D WITH_GCRYPT=ON \
        -D WITH_OPENSSL=OFF \
        -D WITH_SYSTEMD=ON \
        -D WITH_SASL=OFF \
        -D WITH_EXAMPLES=OFF \
        -D WITH_TESTS=OFF \
        -D WITH_SDL=OFF \
        -D WITH_GTK=OFF \
        -D WITH_QT=OFF \
        -D WITH_FFMPEG=OFF \
        -D WITH_XCB=OFF \
        -D WITH_LIBSSHTUNNEL=OFF \
        -G Ninja ..
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
