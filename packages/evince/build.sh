build() {
    mkdir build
    cd build
    # The book's options (gtk_doc=false, nodownload), with every format and
    # optional feature stated so that the build root cannot change the
    # result:
    # - pdf (poppler), tiff and comics (libarchive) on;
    # - djvu (DjVuLibre), dvi (kpathsea from TeX Live), xps (libgxps) and ps
    #   (libspectre) off: none of them has a recipe;
    # - gspell off: it has no recipe (spell checking of annotations);
    # - nautilus off, upstream's default: the property page only builds
    #   against Nautilus older than 43;
    # - internal_synctex: the copy in the tarball, TeX Live does not exist;
    # - keyring (libsecret), printing (gtk+-unix-print), thumbnail cache
    #   (libgnome-desktop-3) and multimedia (GStreamer) on.
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        --wrap-mode=nodownload \
        -D platform=gnome \
        -D development=false \
        -D viewer=true \
        -D previewer=true \
        -D thumbnailer=true \
        -D nautilus=false \
        -D pdf=enabled \
        -D tiff=enabled \
        -D comics=enabled \
        -D djvu=disabled \
        -D dvi=disabled \
        -D xps=disabled \
        -D ps=disabled \
        -D gtk_doc=false \
        -D user_doc=true \
        -D introspection=true \
        -D dbus=true \
        -D keyring=enabled \
        -D gtk_unix_print=enabled \
        -D thumbnail_cache=enabled \
        -D multimedia=enabled \
        -D gspell=disabled \
        -D internal_synctex=true \
        -D systemduserunitdir=/usr/lib/systemd/user
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
