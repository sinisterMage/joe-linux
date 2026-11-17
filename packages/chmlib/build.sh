# Not in the book: last upstream release, mirrored because jedrea.com is gone.
# Verified against Arch's SHA512SUM; integer types patch is upstream commit.
prepare() {
    patch -Np1 -i "$SOURCES/chmlib-integer-types.patch"
    autoreconf -fi
}

build() {
    CFLAGS="${CFLAGS:--O2} -Wno-implicit-function-declaration" \
        ./configure --prefix=/usr --libdir=/usr/lib --disable-static --enable-examples=yes
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
