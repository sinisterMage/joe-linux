prepare() {
    # Animated PNG support, needed by anything that wants to use the system
    # libpng the way browsers do.
    zcat "$SOURCES/libpng-1.6.58-apng.patch.gz" | patch -p1
}

build() {
    ./configure --prefix=/usr --disable-static
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
