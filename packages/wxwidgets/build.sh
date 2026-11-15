# Not in the book: wxWidgets 3.2.12, the newest release of the 3.2 stable
# series, built with configure as docs/gtk/install.md says. The 3.3 series
# is also stable, but the program it is packaged for (Audacity) is
# developed against 3.2 and its 3.0-compatible API, which 3.2 keeps on by
# default.
build() {
    # Every bundled library is replaced by the system's (regex is PCRE2).
    # NanoSVG, a header-only rasteriser, comes with the sources and is used.
    # Left out because joe lacks what they need: wxGLCanvas (wxWidgets 3.2
    # requires GLU), wxWebView (WebKitGTK), CHM help (libmspack), tray icons
    # on Wayland (libayatana-appindicator), SDL sound and GNOME VFS.
    ./configure --prefix=/usr \
        --libdir=/usr/lib \
        --with-gtk=3 \
        --enable-shared \
        --enable-unicode \
        --with-libpng=sys \
        --with-libjpeg=sys \
        --with-libtiff=sys \
        --with-zlib=sys \
        --with-expat=sys \
        --with-regex=sys \
        --with-liblzma \
        --with-libcurl \
        --with-libnotify \
        --with-xtest \
        --enable-secretstore \
        --enable-mediactrl \
        --without-opengl \
        --disable-webview \
        --without-libmspack \
        --without-appindicator \
        --without-sdl \
        --without-gnomevfs
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
