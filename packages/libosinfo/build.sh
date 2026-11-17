# Not in the book: the newest upstream release, built with meson as its
# README says.
prepare() {
    patch -Np1 -i /recipe/libxml2-unused.patch
}

build() {
    mkdir build
    cd build
    # The ids files are named rather than searched for (or downloaded when
    # none is found). The API reference needs gtk-doc.
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        -D enable-introspection=enabled \
        -D enable-vala=enabled \
        -D enable-gtk-doc=false \
        -D enable-tests=false \
        -D libsoup-abi=3.0 \
        -D with-pci-ids-path=/usr/share/hwdata/pci.ids \
        -D with-usb-ids-path=/usr/share/hwdata/usb.ids
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
