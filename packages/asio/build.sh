# Not in the book: the newest stable upstream release (think-async.com lists
# 1.38.2 as stable, 1.39.0 as a development release), standalone (no Boost).
# Only the headers and asio.pc are installed: the examples and tests under
# src/ would be compiled by a plain `make` and are left alone.
build() {
    ./configure --prefix=/usr --without-boost
}

package() {
    make -C include DESTDIR="$DESTDIR" install
    make DESTDIR="$DESTDIR" install-noarch_pkgconfigDATA
}
