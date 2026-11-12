build() {
    mkdir -v build
    (
        cd build
        ../configure --prefix=/usr \
            --sysconfdir=/etc \
            --enable-ld=default \
            --enable-plugins \
            --enable-shared \
            --disable-werror \
            --enable-64-bit-bfd \
            --enable-new-dtags \
            --with-system-zlib \
            --with-lib-path=/usr/lib \
            --enable-default-hash-style=gnu
        # tooldir=/usr: no target-specific /usr/x86_64-pc-linux-gnu directory.
        make tooldir=/usr
    )
}

package() {
    make -C build tooldir=/usr DESTDIR="$DESTDIR" install

    rm -rfv "$DESTDIR"/usr/lib/lib{bfd,ctf,ctf-nobfd,gprofng,opcodes,sframe}.a \
        "$DESTDIR/usr/share/doc/gprofng/"
}
