prepare() {
    # Pre-C23 declarations that GCC 15 rejects, and C99 fixes to configure.
    patch -Np1 -i "$SOURCES/expect-5.45.4-gcc15-1.patch"
}

build() {
    ./configure --prefix=/usr \
        --with-tcl=/usr/lib \
        --enable-shared \
        --disable-rpath \
        --mandir=/usr/share/man \
        --with-tclinclude=/usr/include
    make
}

package() {
    make DESTDIR="$DESTDIR" install
    ln -svf expect5.45.4/libexpect5.45.4.so "$DESTDIR/usr/lib"
}
