# Not in the book: the newest upstream release, built as its README says.
# It has no build options. Its install script compiles the GSettings
# schemas and updates the icon and desktop caches only when DESTDIR is not
# set; those caches are rebuilt by their owners' triggers.
build() {
    mkdir build
    cd build
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
