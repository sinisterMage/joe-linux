# Following the book's raptor page.
prepare() {
    # The book's fix for building against libxml2 2.11 and later.
    sed -i 's/20627/20627 \&\& LIBXML_VERSION < 21100/' src/raptor_libxml.c
}

build() {
    # The JSON parser needs YAJL, which joe Linux does not package; the
    # JSON serializer is built either way. curl is the URI fetcher, as by
    # default; ICU is found and used for the NFC check.
    ./configure --prefix=/usr \
        --disable-static \
        --with-www=curl \
        --with-yajl=no
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
