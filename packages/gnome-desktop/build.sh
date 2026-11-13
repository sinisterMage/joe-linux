build() {
    mkdir build
    cd build
    # All library variants: libgnome-desktop-3 (GTK 3, legacy_library),
    # libgnome-desktop-4, libgnome-bg-4 and libgnome-rr-4 (GTK 4, build_gtk4)
    # and libgnome-qr-4, whose QR code generator is bundled in the tarball
    # (hence nodownload rather than nofallback).
    # desktop_docs: as in the book; copies of the GNU licences as help pages.
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        --wrap-mode=nodownload \
        -D legacy_library=true \
        -D build_gtk4=true \
        -D qr=enabled \
        -D introspection=true \
        -D udev=enabled \
        -D systemd=enabled \
        -D desktop_docs=false \
        -D debug_tools=false \
        -D gtk_doc=false \
        -D installed_tests=false
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
