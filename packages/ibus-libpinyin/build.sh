# Not in the book: the newest upstream release, built as its INSTALL says.
build() {
    # Cloud candidates are built as Fedora builds them; the setting that
    # sends input to a cloud service is off until the user turns it on.
    # OpenCC (simplified and traditional Chinese conversion) has no recipe;
    # without it the engine converts with its own table. Boost is only an
    # alternative to the C++ standard library.
    ./configure --prefix=/usr \
        --sysconfdir=/etc \
        --disable-static \
        --with-python=python3 \
        --disable-schemas-compile \
        --enable-lua-extension \
        --enable-cloud-input-mode \
        --enable-english-input-mode \
        --enable-table-input-mode \
        --enable-libnotify \
        --disable-opencc \
        --disable-boost
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
