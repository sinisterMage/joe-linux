# Following the book's rasqal page, with its optional libgcrypt.
prepare() {
    # configure's probes for libgcrypt and libuuid pass the wrong pointer
    # types (a handle instead of its address; the address of the uuid_t
    # array), which GCC 14 and later reject, so both would silently fall back
    # to rasqal's internal code. Correct the probes.
    sed -i -e 's/gcry_md_open(hash, GCRY_MD_MD5, 0)/gcry_md_open(\&hash, GCRY_MD_MD5, 0)/' \
        -e 's/uuid_clear(&data)/uuid_clear(data)/' configure
    [[ $(grep -c 'gcry_md_open(&hash' configure) == 1 && $(grep -c 'uuid_clear(data)' configure) == 2 ]]
}

build() {
    # configure finds libgcrypt only through libgcrypt-config, which
    # libgcrypt no longer installs (joe's ships libgcrypt.pc instead), and
    # otherwise falls back silently to internal MD5 and SHA-1 only. Give it
    # a stand-in that answers from pkg-config.
    cat > gcrypt-config.sh <<'SHIM'
#!/bin/sh
case "$1" in
--version) exec pkg-config --modversion libgcrypt ;;
--cflags) exec pkg-config --cflags libgcrypt ;;
--libs) exec pkg-config --libs libgcrypt ;;
esac
exit 1
SHIM
    chmod 755 gcrypt-config.sh

    # Regular expressions come from glibc's POSIX regex: the alternative is
    # the old PCRE 1 library (pcre-config), which joe Linux does not have.
    ./configure --prefix=/usr \
        --disable-static \
        --disable-pcre \
        --with-regex-library=posix \
        --with-libgcrypt-config="$PWD/gcrypt-config.sh" \
        --with-digest-library=gcrypt \
        --with-uuid-library=libuuid \
        --with-decimal=mpfr \
        --enable-xml2
    # Fail here rather than ship the internal fallback without saying so.
    grep -q '^#define RASQAL_DIGEST_GCRYPT 1' src/rasqal_config.h
    grep -q '^#define RASQAL_UUID_LIBUUID 1' src/rasqal_config.h
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
