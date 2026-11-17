# Not in the book: the newest upstream release, built with CMake as
# READMEs/README.build.md describes, with the feature set Arch Linux uses
# plus every event library joe packages.
prepare() {
    # The install step runs useradd to create lwsws users (for the lwsws
    # web server, not built here), which would change the shared build
    # root's /etc/passwd. Accounts are sysusers.d's job.
    sed -i '/execute_process(COMMAND useradd -r -M lwsws/d' CMakeLists.txt
    if grep -q useradd CMakeLists.txt; then
        echo 'libwebsockets: useradd is still in CMakeLists.txt' >&2
        return 1
    fi
}

build() {
    # - TLS from OpenSSL (system CA certificates; its SHA-1 instead of the
    #   built-in one). HTTP/3 and QUIC are off: with OpenSSL they need the
    #   quictls fork's SSL_set_quic_method, which OpenSSL itself lacks.
    # - Event libraries as runtime plugins, so libev and libevent can both
    #   be built; uloop (OpenWrt's libubox) has no recipe.
    # - permessage-deflate (extensions) and zipped file serving with zlib.
    # - Off: the static library, test applications, minimal examples,
    #   lwsws, protocol plugins, mbedTLS and the other TLS libraries, and
    #   -Werror.
    cmake -B build -G Ninja \
        -D CMAKE_INSTALL_PREFIX=/usr \
        -D CMAKE_INSTALL_LIBDIR=lib \
        -D CMAKE_BUILD_TYPE=Release \
        -D DISABLE_WERROR=ON \
        -D LWS_WITH_SHARED=ON \
        -D LWS_WITH_STATIC=OFF \
        -D LWS_WITHOUT_TESTAPPS=ON \
        -D LWS_WITH_MINIMAL_EXAMPLES=OFF \
        -D LWS_WITH_LWSWS=OFF \
        -D LWS_WITH_PLUGINS=OFF \
        -D LWS_WITH_SSL=ON \
        -D LWS_WITH_MBEDTLS=OFF \
        -D LWS_WITH_GNUTLS=OFF \
        -D LWS_SSL_CLIENT_USE_OS_CA_CERTS=ON \
        -D LWS_WITHOUT_BUILTIN_SHA1=ON \
        -D LWS_WITHOUT_BUILTIN_GETIFADDRS=ON \
        -D LWS_WITH_HTTP3=OFF \
        -D LWS_ROLE_QUIC=OFF \
        -D LWS_WITH_HTTP2=ON \
        -D LWS_IPV6=ON \
        -D LWS_UNIX_SOCK=ON \
        -D LWS_WITH_LIBCAP=ON \
        -D LWS_WITH_ZLIB=ON \
        -D LWS_WITHOUT_EXTENSIONS=OFF \
        -D LWS_WITH_ZIP_FOPS=ON \
        -D LWS_WITH_EVLIB_PLUGINS=ON \
        -D LWS_WITH_LIBUV=ON \
        -D LWS_WITH_LIBEV=ON \
        -D LWS_WITH_LIBEVENT=ON \
        -D LWS_WITH_GLIB=ON \
        -D LWS_WITH_SDEVENT=ON \
        -D LWS_WITH_ULOOP=OFF \
        -D LWS_WITH_EXTERNAL_POLL=ON \
        -D LWS_WITH_SOCKS5=ON \
        -D LWS_WITH_HTTP_PROXY=ON \
        -D LWS_WITH_RANGES=ON \
        -D LWS_WITH_THREADPOOL=ON \
        -D LWS_WITH_DISKCACHE=ON \
        -D LWS_WITH_FTS=ON \
        -D LWS_WITH_LWSAC=ON
    ninja -C build
}

package() {
    DESTDIR="$DESTDIR" ninja -C build install
}
