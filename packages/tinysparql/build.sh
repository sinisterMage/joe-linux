build() {
    mkdir build
    cd build
    # ICU is the Unicode library. No Avahi and no libstemmer; the manual
    # pages need asciidoc and the reference needs gi-docgen. localsearch, the
    # indexer the book recommends at run time, is a separate package.
    meson setup .. \
        --prefix=/usr \
        --buildtype=release \
        -D unicode_support=icu \
        -D introspection=enabled \
        -D vapi=enabled \
        -D systemd_user_services=true \
        -D avahi=disabled \
        -D stemmer=disabled \
        -D bash_completion=false \
        -D docs=false \
        -D man=false \
        -D tests=false
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
