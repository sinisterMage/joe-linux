# Not in the book: the newest upstream release, built as its INSTALL.md says.
# A library only: nothing is preloaded globally (jemalloc.sh does that for
# one command when asked).
build() {
    # Heap profiling (--enable-prof, inactive unless MALLOC_CONF asks for it)
    # so that the jeprof script that is always installed has something to
    # read; backtraces come from libgcc's unwinder, not libunwind. The manual
    # page is the one in the tarball: docbook-xsl is not where configure
    # looks, so it is installed as shipped rather than regenerated.
    ./configure --prefix=/usr \
        --libdir=/usr/lib \
        --disable-static \
        --enable-prof \
        --disable-prof-libunwind
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
