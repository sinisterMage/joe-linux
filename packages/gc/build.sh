build() {
    # The book's options. libatomic_ops has no recipe; GC uses the
    # compiler's atomic intrinsics instead, said explicitly.
    ./configure --prefix=/usr \
        --enable-cplusplus \
        --disable-static \
        --with-libatomic-ops=none \
        --docdir=/usr/share/doc/gc-8.2.12
    make
}

package() {
    make DESTDIR="$DESTDIR" install
    install -v -d -m755 "$DESTDIR/usr/share/man/man3"
    install -v -m644 doc/gc.man "$DESTDIR/usr/share/man/man3/gc_malloc.3"
}
