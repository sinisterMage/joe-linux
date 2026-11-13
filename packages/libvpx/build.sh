prepare() {
    # The book's two fixes: the archive's time stamps confuse make, and
    # "cp -p" would carry the build user's ownership into the package.
    find -type f | xargs touch
    sed -i 's/cp -p/cp/' build/make/Makefile
}

build() {
    mkdir libvpx-build
    cd libvpx-build
    # --as=nasm: configure would prefer yasm, which has no recipe.
    # No unit tests (they download their data) and no Doxygen documentation.
    ../configure --prefix=/usr \
        --libdir=/usr/lib \
        --enable-shared \
        --disable-static \
        --as=nasm \
        --disable-unit-tests \
        --disable-docs
    make
}

package() {
    cd libvpx-build
    make DESTDIR="$DESTDIR" install
}
