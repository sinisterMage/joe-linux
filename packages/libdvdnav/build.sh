# Following the book's libdvdnav page (its sed only renames the
# documentation directory, which is not shipped). Encrypted discs need
# libdvdcss, which libdvdread loads at run time when it is present and which
# has no recipe.
build() {
    mkdir build
    cd build
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        --default-library=shared \
        --wrap-mode=nofallback \
        -D enable_docs=false \
        -D enable_examples=false
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
