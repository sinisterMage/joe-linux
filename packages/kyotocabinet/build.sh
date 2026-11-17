# Not in the book: the newest upstream release, built as its README says.
build() {
    # ZLIB compression is on by default; LZO and LZMA are optional and off.
    ./configure --prefix=/usr \
        --libdir=/usr/lib \
        --disable-lzo \
        --disable-lzma
    make
}

package() {
    make DESTDIR="$DESTDIR" install
    # The static library is always installed; nothing needs it.
    rm "$DESTDIR/usr/lib/libkyotocabinet.a"
}
