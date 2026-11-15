# Not in the book: the newest upstream release (5.9.0), built with its
# configure script. The programs (wavpack, wvunpack, wvgain, wvtag) are
# built too; their iconv is glibc's. Upstream's defaults otherwise: DSD
# support and threading on, decoding of pre-4.0 files off.
build() {
    ./configure --prefix=/usr \
        --disable-static \
        --disable-rpath
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
