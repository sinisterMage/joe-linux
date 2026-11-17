# Not in the book: the newest upstream release, built with meson as its
# README says.
build() {
    mkdir build
    cd build
    # gtk-frdp comes with the tarball (subprojects/gtk-frdp) and is
    # installed privately in /usr/lib/gnome-connections; nodownload keeps
    # meson from fetching anything. SPICE support is found automatically
    # when spice-gtk and its vapi are present, which they are.
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        --wrap-mode=nodownload \
        -D profile=default
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
