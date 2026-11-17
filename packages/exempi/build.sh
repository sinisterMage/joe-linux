# Following the book's exempi page (checked against its MD5, and the
# release's signature by Hubert Figuiere, DSA key
# 6C44DB3E0BF3EAF5B433239A5FEE05E6A56E15A3). Papers needs it.
build() {
    # The book requires Boost for the unit tests, which are not built here,
    # so its sed and autoreconf (which drop one test) are not needed.
    # - samples: example programs that are not installed.
    ./configure \
        --prefix=/usr \
        --disable-static \
        --enable-unittest=no \
        --enable-samples=no
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
