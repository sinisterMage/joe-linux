# Not in the book: the newest upstream release, built with meson as its
# README says.
build() {
    mkdir build
    cd build
    # in-app-browser would open links in an embedded WebKitGTK 6 view;
    # WebKitGTK has no recipe yet, so links open in the default browser.
    # distro leaves the schema, icon and desktop caches to the triggers.
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        -D devel=false \
        -D distro=true \
        -D spelling=enabled \
        -D clapper=enabled \
        -D gstreamer=enabled \
        -D gexiv2=enabled \
        -D in-app-browser=disabled
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
