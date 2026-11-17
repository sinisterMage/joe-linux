# Not in the book: the newest upstream release, built with meson as its
# README says. grilo-test-ui, a GTK 3 program for trying plugins out, is a
# developer's tool and is not built; grl-inspect and grl-launch are.
build() {
    mkdir build
    cd build
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        -D enable-grl-net=true \
        -D enable-grl-pls=true \
        -D soup3=true \
        -D enable-introspection=true \
        -D enable-vala=true \
        -D enable-gtk-doc=false \
        -D enable-test-ui=false
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
