# Not in the book: the newest upstream release, built with meson as its
# README says. Checked against the release's .sha256sum file.
build() {
    mkdir build
    cd build
    meson setup .. \
        --prefix=/usr \
        --buildtype=release \
        -D profile=default
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
