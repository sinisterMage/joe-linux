build() {
    mkdir build
    cd build
    # The book's options (its sed only renames the documentation directory,
    # which is not shipped). libdvdcss is not linked: there is no recipe for
    # it, and libdvdread loads it at run time when it is present.
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        --default-library=shared \
        --wrap-mode=nofallback \
        -D libdvdcss=disabled \
        -D enable_docs=false
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
