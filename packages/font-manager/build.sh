# Not in the book: the newest upstream release, built with meson as its
# INSTALL says. Checked against the release's .sha256sum file.
build() {
    mkdir build
    cd build
    # - webkit: Google Fonts browsing needs WebKitGTK, which has no recipe
    #   yet (it is a later batch); the rest of the program does not use it.
    # - yelp-doc: the help pages need yelp-tools, which has no recipe.
    # - nemo, thunar: those file managers have no recipes.
    # - reproducible: no build date in the program.
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        -D manager=true \
        -D viewer=true \
        -D search-provider=true \
        -D adwaita=true \
        -D webkit=false \
        -D libarchive=true \
        -D yelp-doc=false \
        -D enable-nls=true \
        -D unihan=true \
        -D nautilus=true \
        -D nemo=false \
        -D thunar=false \
        -D gtk-doc=false \
        -D reproducible=true \
        -D app-armor=false
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
