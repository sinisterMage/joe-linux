# Not in the book: the newest upstream release, built with meson as its
# INSTALL.md says.
build() {
    mkdir build
    cd build
    # The icon and GSettings caches are rebuilt by the triggers of the
    # packages that own those tools, not at install time. Only QEMU/KVM is
    # offered in the Open Connection dialog, since libvirt is built with no
    # other hypervisor driver. The GtkSourceView 4 XML highlighting is not
    # available (gtksourceview4 is not packaged); the XML editor is then a
    # plain text view.
    meson setup .. \
        --prefix=/usr \
        --buildtype=release \
        -D update-icon-cache=false \
        -D compile-schemas=false \
        -D default-graphics=spice \
        -D default-hvs=qemu \
        -D tests=disabled
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install

    # The modules live in /usr/share/virt-manager rather than in Python's
    # site-packages, so nothing compiles them on installation. Without byte
    # code Python would compile them on every start, and virt-install run
    # as root would write .pyc files beside them.
    python3 -m compileall -q -s "$DESTDIR" -p / "$DESTDIR/usr/share/virt-manager"
}
