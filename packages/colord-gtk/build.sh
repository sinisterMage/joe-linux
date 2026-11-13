build() {
    mkdir build
    cd build
    # man: the page for cd-convert is written in DocBook 5, whose stylesheets
    # (docbook-xsl-ns) do not exist here; the book leaves it off as well.
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        -D gtk4=true \
        -D gtk3=true \
        -D gtk2=false \
        -D introspection=true \
        -D vapi=true \
        -D tests=false \
        -D docs=false \
        -D man=false
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
