# Not in the book: the newest upstream release, built as its README says,
# with the TLS and crypto libraries Arch and Debian use.
prepare() {
    # Nettle 4 dropped the length argument of the digest functions (Arch's
    # nettle-4.patch makes the same change).
    sed -i 's/hash->digest(ctx_.get(), getDigestLength(), md);/hash->digest(ctx_.get(), md);/' \
        src/LibnettleMessageDigestImpl.cc
    grep -q 'hash->digest(ctx_.get(), md);' src/LibnettleMessageDigestImpl.cc
}

build() {
    # GnuTLS, with no CA bundle compiled in: GnuTLS's system trust (the
    # p11-kit trust module, anchors from make-ca) is used when
    # --ca-certificate is not given. OpenSSL and libgcrypt are refused so
    # that configure cannot choose them instead; libuv, tcmalloc and
    # jemalloc are off by default. The bash completion goes where
    # bash-completion looks rather than into the documentation directory.
    ./configure --prefix=/usr \
        --with-gnutls \
        --with-libnettle \
        --with-libgmp \
        --without-openssl \
        --without-libgcrypt \
        --with-libssh2 \
        --with-libcares \
        --with-sqlite3 \
        --with-libxml2 \
        --without-libexpat \
        --with-libz \
        --without-libuv \
        --without-tcmalloc \
        --without-jemalloc \
        --enable-bittorrent \
        --enable-metalink \
        --enable-websocket \
        --with-bashcompletiondir=/usr/share/bash-completion/completions
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
