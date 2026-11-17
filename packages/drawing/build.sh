# Not in the book: the newest upstream release, built with meson as its
# CONTRIBUTING.md ("Install from source code") says. Upstream publishes no
# checksum for the release archive.
build() {
    mkdir build
    cd build
    meson setup .. \
        --prefix=/usr \
        --buildtype=release \
        -D enable-translations-and-appdata=true \
        -D use-uuid-as-binary-name=false
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
