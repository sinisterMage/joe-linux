# Not in the book: the newest upstream release, built as its INSTALL says.
build() {
    # CURVE security through libsodium rather than the bundled TweetNaCl,
    # and the GSSAPI mechanism through krb5. Draft APIs (and with them the
    # WebSocket transport and its TLS) stay off as in upstream's release.
    # No libbsd (no recipe), PGM, NORM or VMCI. -Werror is upstream's
    # default and only breaks builds with newer compilers. The manual
    # pages are prebuilt in the tarball.
    ./configure --prefix=/usr \
        --disable-static \
        --disable-Werror \
        --with-libsodium \
        --with-libgssapi_krb5 \
        --enable-libunwind \
        --disable-libbsd \
        --disable-drafts \
        --without-pgm \
        --without-norm \
        --without-vmci \
        --without-nss
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
