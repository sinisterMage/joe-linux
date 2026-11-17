# Not in the book: upstream release, built with Autotools.
# Upstream publishes no checksum for its GitHub tag archive.
prepare() {
    autoreconf -fi
}

build() {
    ./configure --prefix=/usr --libdir=/usr/lib --disable-static
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
