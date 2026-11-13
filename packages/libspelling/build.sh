build() {
    mkdir build
    cd build
    # The book's options (no documentation, no sysprof). enchant=enabled is
    # the default, spelled out: Enchant is the library's only spelling
    # provider (here with Hunspell behind it, dictionaries in
    # /usr/share/hunspell), and it brings ICU, which finds the word
    # boundaries.
    # --wrap-mode=nodownload: sysprof is named as a subproject to fetch.
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        --wrap-mode=nodownload \
        -D docs=false \
        -D sysprof=false \
        -D enchant=enabled \
        -D introspection=enabled \
        -D vapi=true \
        -D install-static=false
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
