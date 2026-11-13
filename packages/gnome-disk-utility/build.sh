build() {
    mkdir build
    cd build
    # The book builds with the defaults, stated here. --wrap-mode=nofallback
    # keeps meson from fetching libhandy as a subproject. The manual pages
    # are made with xsltproc from the installed DocBook stylesheets
    # (--nonet).
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        --wrap-mode=nofallback \
        -D logind=libsystemd \
        -D gsd_plugin=true \
        -D man=true
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
