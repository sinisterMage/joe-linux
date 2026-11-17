# Not in the book: Snowball upstream stable release; no upstream archive checksum.
# Upstream only builds a static archive; link its PIC objects into a shared ABI.
build() {
    make CFLAGS="${CFLAGS:--O2} -fPIC" libstemmer.a
    ${CC:-cc} -shared -Wl,-soname,libstemmer.so.3 -o libstemmer.so.3.2.0 \
        -Wl,--whole-archive libstemmer.a -Wl,--no-whole-archive
}

package() {
    install -Dm644 include/libstemmer.h "$DESTDIR/usr/include/libstemmer.h"
    install -Dm755 libstemmer.so.3.2.0 "$DESTDIR/usr/lib/libstemmer.so.3.2.0"
    ln -s libstemmer.so.3.2.0 "$DESTDIR/usr/lib/libstemmer.so.3"
    ln -s libstemmer.so.3 "$DESTDIR/usr/lib/libstemmer.so"
}
