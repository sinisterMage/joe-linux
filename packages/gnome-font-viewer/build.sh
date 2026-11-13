# There is no book page. gnome-font-viewer made no 51 release; 50.0 is the
# newest stable one and is what GNOME 51 ships. Upstream's meson options at
# their defaults.
build() {
    mkdir build
    cd build
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        -D profile=default
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
