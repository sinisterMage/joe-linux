# Not in the book (libqmi's page lists it as optional): the newest upstream
# release, built as its README says.
build() {
    mkdir build
    cd build
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        -D introspection=true \
        -D gtk_doc=false
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
