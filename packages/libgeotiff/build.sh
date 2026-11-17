# Not in the book: the newest upstream release, built with its configure
# script as its INSTALL says, with PROJ (coordinate systems), and JPEG and
# zlib for the compressed TIFFs geotifcp writes. The Doxygen documentation
# is not generated.
prepare() {
    patch -Np1 -i /recipe/pseudo-mercator.patch
}

build() {
    ./configure --prefix=/usr \
        --disable-static \
        --with-proj \
        --with-jpeg \
        --with-zip \
        --disable-doxygen-doc
    make
    ${CC:-cc} -O2 -I. /recipe/test-projection.c -L.libs -lgeotiff -lm -o test-projection
    LD_LIBRARY_PATH="$PWD/.libs${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" ./test-projection
}

package() {
    make DESTDIR="$DESTDIR" install
}
