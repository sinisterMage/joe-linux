prepare() {
    # The page's required patch. It only touches the Qt 6 backend, which is
    # not built here, and is applied to stay with the book.
    patch -Np1 -i "$SOURCES/libportal-0.9.1-qt6.9_fixes-1.patch"
}

build() {
    mkdir build
    cd build
    # Qt does not exist here. Vala does, so the bindings the book switches
    # off are built.
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        --wrap-mode=nofallback \
        -D backend-gtk3=enabled \
        -D backend-gtk4=enabled \
        -D backend-qt5=disabled \
        -D backend-qt6=disabled \
        -D introspection=true \
        -D vapi=true \
        -D docs=false \
        -D tests=false \
        -D portal-tests=false
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
