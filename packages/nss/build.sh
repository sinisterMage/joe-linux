# The build signs libsoftokn3, libfreebl3, libfreeblpriv3 and libnssdbm3: the
# .chk files hold a checksum of each library, verified when NSS runs in FIPS
# mode. Stripping the libraries afterwards would invalidate them. BUILD_OPT=1
# already compiles without debugging information.
NOSTRIP=1

prepare() {
    # nss.pc and nss-config, and building against the system NSPR.
    patch -Np1 -i "$SOURCES/nss-standalone-1.patch"
}

build() {
    cd nss
    # NSS_DISABLE_GTESTS=1: the test suite is not run, so do not compile it.
    make BUILD_OPT=1 \
        NSPR_INCLUDE_DIR=/usr/include/nspr \
        USE_SYSTEM_ZLIB=1 \
        ZLIB_LIBS=-lz \
        NSS_ENABLE_WERROR=0 \
        NSS_USE_SYSTEM_SQLITE=1 \
        NSS_DISABLE_GTESTS=1 \
        $([ $(uname -m) = x86_64 ] && echo USE_64=1)
}

package() {
    cd dist

    install -v -m755 -d "$DESTDIR/usr/lib/pkgconfig" "$DESTDIR/usr/bin"

    install -v -m755 Linux*/lib/*.so "$DESTDIR/usr/lib"
    install -v -m644 Linux*/lib/*.chk "$DESTDIR/usr/lib"

    install -v -m755 -d "$DESTDIR/usr/include/nss"
    cp -v -RL {public,private}/nss/* "$DESTDIR/usr/include/nss"

    install -v -m755 Linux*/bin/{certutil,nss-config,pk12util} "$DESTDIR/usr/bin"

    install -v -m644 Linux*/lib/pkgconfig/nss.pc "$DESTDIR/usr/lib/pkgconfig"

    # /usr/lib/libnssckbi.so is p11-kit's link to its trust module, which
    # gives NSS applications the system trust store instead of the static
    # root list compiled into this library.
    rm -fv "$DESTDIR/usr/lib/libnssckbi.so"
}
