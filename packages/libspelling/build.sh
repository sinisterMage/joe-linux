build() {
    mkdir build
    cd build
    # The book's options (no documentation, no sysprof), plus:
    # - enchant=disabled: Enchant, which the book recommends, needs Aspell
    #   and a dictionary, and none of them exists here. The library then
    #   has no spelling provider: its users (Text Editor) build and run, but
    #   check nothing. Switch this on when an enchant recipe is added (it
    #   also needs ICU).
    # --wrap-mode=nodownload: sysprof is named as a subproject to fetch.
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        --wrap-mode=nodownload \
        -D docs=false \
        -D sysprof=false \
        -D enchant=disabled \
        -D introspection=enabled \
        -D vapi=true \
        -D install-static=false
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
