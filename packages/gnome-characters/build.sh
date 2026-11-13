# There is no book page: this is the GNOME 51 release, built with upstream's
# meson options at their defaults.
build() {
    mkdir build
    cd build
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        -D profile=default \
        -D pangoft2=true \
        -D installed_tests=false
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
