build() {
    mkdir build
    cd build
    # The book builds with the defaults. Stated here: the application, its
    # GCalc and GCi libraries and their typelibs; no Valadoc reference
    # (valadoc is not built by the vala recipe) and no UI tests.
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        --wrap-mode=nofallback \
        -D app=true \
        -D gcalc=true \
        -D gci=true \
        -D disable-ui=false \
        -D disable-introspection=false \
        -D doc=false \
        -D ui-tests=false \
        -D development=false
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
