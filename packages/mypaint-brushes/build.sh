build() {
    # Maintainer mode is on by default here; turned off so that make never
    # tries to rerun automake.
    ./configure --prefix=/usr --disable-maintainer-mode
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
