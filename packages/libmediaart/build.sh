# Not in the book: the newest upstream release, built with meson as its
# README says. Images are scaled with GdkPixbuf (the alternative is Qt 5).
build() {
    mkdir build
    cd build
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        -D image_library=gdk-pixbuf \
        -D introspection=true \
        -D vapi=true \
        -D tests=false \
        -D gtk_doc=false
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
