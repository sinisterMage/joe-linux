# Not in the book: the newest release of the 3.6 long-term support branch
# (supported until at least March 2027), built with CMake as its README
# says. Mbed TLS 4 (4.2.0) is newer, but it changed the API and what needs
# Mbed TLS here (OBS Studio's RTMPS output) accepts only 3.x, as most
# distributions' 3.6 packages exist for.
#
# Shared libraries only (libmbedtls, libmbedx509, libmbedcrypto), with the
# CMake package and pkg-config files. The example and utility programs
# under programs/ are not installed (they have generic names such as
# `benchmark` and `hello`); nor are the tests built.

prepare() {
    # As Arch Linux configures it: thread safety through pthreads,
    # which programs that use one context from several threads need, and the
    # SSE2 code paths every x86-64 processor has.
    python3 scripts/config.py set MBEDTLS_THREADING_C
    python3 scripts/config.py set MBEDTLS_THREADING_PTHREAD
    python3 scripts/config.py set MBEDTLS_HAVE_SSE2
}

build() {
    cmake -B build -G Ninja \
        -D CMAKE_INSTALL_PREFIX=/usr \
        -D CMAKE_INSTALL_LIBDIR=lib \
        -D CMAKE_BUILD_TYPE=Release \
        -D USE_SHARED_MBEDTLS_LIBRARY=ON \
        -D USE_STATIC_MBEDTLS_LIBRARY=OFF \
        -D LINK_WITH_PTHREAD=ON \
        -D ENABLE_PROGRAMS=OFF \
        -D ENABLE_TESTING=OFF \
        -D MBEDTLS_FATAL_WARNINGS=OFF \
        -D GEN_FILES=OFF
    ninja -C build
}

package() {
    DESTDIR="$DESTDIR" cmake --install build
}
