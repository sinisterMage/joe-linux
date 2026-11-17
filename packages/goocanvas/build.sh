# Not in the book: newest stable GNOME release, following upstream INSTALL.
prepare() {
    # GLib's g_object_ref returns its argument's type, so GCC 14 and later
    # reject storing the item model in the simple model's field uncast.
    sed -i 's/^  item->model = g_object_ref (model);$/  item->model = (GooCanvasItemModelSimple *) g_object_ref (model);/' \
        src/goocanvasitemsimple.c
    grep -q '(GooCanvasItemModelSimple \*) g_object_ref (model)' src/goocanvasitemsimple.c
}

build() {
    ./configure --prefix=/usr --libdir=/usr/lib \
        --disable-static --enable-introspection \
        --disable-python --disable-gtk-doc
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
