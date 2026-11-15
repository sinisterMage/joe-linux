# Not in the book: the newest upstream release, built with autotools as
# INSTALL describes. Speech Dispatcher reads its configuration with it.
prepare() {
    # The archive of the release tag carries configure.ac only.
    autoreconf -fi
}

build() {
    ./configure --prefix=/usr --disable-static
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
