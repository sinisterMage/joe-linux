# Not in the book: the newest upstream release, built with meson as its
# README says.
prepare() {
    # The install script would run setcap on the USB ACL helper inside
    # $DESTDIR, or chown it; package() makes it set-uid root instead, as
    # Fedora does.
    sed -i "/setcap-or-suid/d" src/meson.build
}

build() {
    mkdir build
    cd build
    # Off, because what they need is not packaged: folder sharing over
    # WebDAV (phodav) and smartcards (libcacard). The API reference needs
    # gi-docgen.
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        -D gtk=enabled \
        -D egl=enabled \
        -D wayland-protocols=enabled \
        -D webdav=disabled \
        -D builtin-mjpeg=true \
        -D usbredir=enabled \
        -D libcap-ng=enabled \
        -D polkit=enabled \
        -D usb-ids-path=/usr/share/hwdata/usb.ids \
        -D introspection=enabled \
        -D vapi=enabled \
        -D lz4=enabled \
        -D opus=enabled \
        -D sasl=enabled \
        -D smartcard=disabled \
        -D gtk_doc=disabled \
        -D valgrind=false \
        -D spice-common:tests=false \
        -D spice-common:manual=false
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install

    chmod 4755 "$DESTDIR/usr/libexec/spice-client-glib-usb-acl-helper"
}
