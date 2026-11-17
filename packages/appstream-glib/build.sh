# Not in the book: upstream release and SHA256SUMS; RPM/ALPM are foreign package managers.
build() {
    meson setup build --prefix=/usr --libdir=lib --buildtype=release \
        --wrap-mode=nodownload -Ddep11=true -Dbuilder=true -Drpm=false -Dalpm=false -Dfonts=true -Dman=true -Dgtk-doc=false -Dintrospection=true
    ninja -C build
}

package() {
    DESTDIR="$DESTDIR" ninja -C build install
}
