build() {
    # configure.ac sets the default prefix to /usr, which is why the book
    # passes nothing; say it anyway.
    ./configure --prefix=/usr --libdir=/usr/lib
    make
}

package() {
    make DESTDIR="$DESTDIR" install

    # The book's "recommended configuration files": the use case manager
    # profiles, which sound servers need to drive most modern laptops.
    tar -C "$DESTDIR/usr/share/alsa" --strip-components=1 \
        --no-same-owner --no-same-permissions \
        -xf "$SOURCES/alsa-ucm-conf-1.2.16.1.tar.bz2"
}
