# Not in the book: newest upstream release, following its Meson build.
build() {
    meson setup build --prefix=/usr --libdir=lib --buildtype=release \
        --wrap-mode=nofallback -Ddocs=disabled
    ninja -C build
}

package() {
    DESTDIR="$DESTDIR" ninja -C build install
    install -Dm644 COPYING "$DESTDIR/usr/share/licenses/nautilus-python/COPYING"
}
