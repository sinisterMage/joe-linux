# Following the book's yelp-xsl page; GNOME SHA256SUMS verified.
build() {
    meson setup build --prefix=/usr --libdir=lib --buildtype=release \
        --wrap-mode=nodownload 
    ninja -C build
}

package() {
    DESTDIR="$DESTDIR" ninja -C build install
}
