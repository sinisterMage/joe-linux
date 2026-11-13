prepare() {
    # Put the external proxy settings schema under /org/gnome like the rest.
    sed -i -r 's:"(/system):"/org/gnome\1:g' src/external.gschema.xml
}

build() {
    mkdir build
    cd build
    # The book builds with the defaults. Here the documentation is off: the
    # manual page wants the DocBook stylesheets by URL and the help pages
    # have no reader (yelp) to show them. The search provider is built from
    # an interface description shipped in the tarball, so gnome-shell is not
    # needed to build it.
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        --wrap-mode=nodownload \
        -D docs=false \
        -D dbg=false \
        -D nautilus_extension=true \
        -D search_provider=true
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
