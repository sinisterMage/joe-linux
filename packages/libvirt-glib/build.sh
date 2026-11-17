# Not in the book: the newest upstream release, built with meson as its
# README says.
build() {
    mkdir build
    cd build
    # GObject introspection data and Vala bindings are what virt-manager and
    # virt-viewer use; the reference manual needs gtk-doc.
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        -D introspection=enabled \
        -D vapi=enabled \
        -D docs=disabled \
        -D tests=disabled \
        -D rpath=disabled \
        -D git_werror=disabled
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
