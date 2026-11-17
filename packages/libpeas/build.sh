# Following the book's libpeas page. Upstream's newest release is 2.2.1,
# but that is libpeas-2, a different API (GTK-free) installed beside this
# one; this is the libpeas-1.0 series that the book carries and that
# Rhythmbox, gitg and Eye of GNOME use.
build() {
    mkdir build
    cd build
    # The book passes -D python3=false. PyGObject has a recipe, so the
    # Python 3 loader is built here: Python plugins (Rhythmbox has many)
    # need it.
    # - lua51: needs lua-lgi, which has no recipe.
    # - glade_catalog: needs Glade, which has no recipe.
    # - demos: the peas-demo program and its plugins.
    # The vapi is not generated: Vala ships libpeas-1.0.vapi itself.
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        --wrap-mode=nofallback \
        -D python3=true \
        -D python2=false \
        -D lua51=false \
        -D introspection=true \
        -D vapi=false \
        -D widgetry=true \
        -D glade_catalog=false \
        -D demos=false \
        -D gtk_doc=false
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
