# Not in the book: upstream's latest stable release, built with its Meson project.
# Use system text libraries only; FriBidi is the supported packaged bidi engine.
build() {
    meson setup build --prefix=/usr --libdir=lib --buildtype=release \
        --wrap-mode=nofallback --default-library=shared \
        -D docs=false -D tests=false -D sheenbidi=false
    ninja -C build
}

package() {
    DESTDIR="$DESTDIR" ninja -C build install
}
