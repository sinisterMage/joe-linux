build() {
    mkdir build
    cd build
    # The book's switches; the manual pages need help2man. Introspection is
    # stated.
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        -D introspection=true \
        -D bash_completion=false \
        -D gtk_doc=false \
        -D man=false
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
