# Following the book's libass page, with the book's recommended Fontconfig
# (system fonts) and NASM, and HarfBuzz, which this release requires.
# libunibreak (Unicode line breaking) has no recipe.
build() {
    ./configure --prefix=/usr \
        --disable-static \
        --enable-fontconfig \
        --enable-asm \
        --disable-libunibreak \
        --disable-test \
        --disable-compare \
        --disable-profile \
        --disable-fuzz
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
