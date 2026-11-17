# Not in the book: the newest upstream release, built as its INSTALL
# says. The example and test programs are not installed (upstream builds
# them as noinst).
prepare() {
    # The release tarball contains three stale libtool archives from the
    # maintainer's own build; remove them so that nothing mistakes them for
    # this build's.
    rm -f libmspack.la libmscabd.la libmschmd.la
}

build() {
    ./configure --prefix=/usr --disable-static
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
