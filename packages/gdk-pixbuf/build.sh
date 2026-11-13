build() {
    mkdir build
    cd build
    # The book switches the PNG, JPEG, TIFF and GIF loaders off because its
    # second build of this package hands all decoding to glycin. This is the
    # only build, and it is without glycin (see package.zon), so the loaders
    # stay on, together with the "others" set (BMP, ICO, XPM, ...) that
    # glycin would otherwise cover. SVG comes from librsvg's loader module.
    # The thumbnailer stays off as in the book.
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        --wrap-mode=nofallback \
        -D glycin=disabled \
        -D png=enabled \
        -D jpeg=enabled \
        -D tiff=enabled \
        -D gif=enabled \
        -D others=enabled \
        -D thumbnailer=disabled \
        -D introspection=enabled \
        -D man=true \
        -D documentation=false \
        -D tests=false \
        -D installed_tests=false
    ninja
}

package() {
    cd build
    # With DESTDIR set the install script leaves loaders.cache alone; the
    # trigger writes it on the installed system.
    DESTDIR="$DESTDIR" ninja install

    # loaders.cache lists every loader module, whichever package ships it.
    install -d "$DESTDIR/usr/lib/dave/triggers"
    cat > "$DESTDIR/usr/lib/dave/triggers/34-gdk-pixbuf-loaders.zon" <<'EOT'
.{
    .name = "gdk-pixbuf loader cache",
    .paths = .{"usr/lib/gdk-pixbuf-2.0/"},
    .exec = .{ "/usr/bin/gdk-pixbuf-query-loaders", "--update-cache" },
}
EOT
}
