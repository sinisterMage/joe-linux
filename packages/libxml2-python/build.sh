# Not a page of the book: the book builds libxml2 without its Python
# bindings, as the libxml2 package does. Here libxml2 is built again,
# configured as the libxml2 package with the bindings added, and only the
# bindings are packaged, the way other distributions split python3-libxml2
# from one libxml2 build. virt-manager's virtinst needs them.
prepare() {
    # An unnecessary call to git (as in the libxml2 package).
    sed -i "/'git'/,+3d" meson.build
}

build() {
    mkdir build
    cd build
    meson setup .. \
        --prefix=/usr \
        --buildtype=release \
        -D libdir=lib \
        -D history=enabled \
        -D icu=enabled \
        -D python=enabled
    ninja
}

package() {
    cd build
    # Install everything into a scratch tree and keep only Python's part.
    local stage="$PWD/stage"
    DESTDIR="$stage" ninja install
    cd "$stage"
    cp -a --parents usr/lib/python3.*/site-packages "$DESTDIR/"
}
