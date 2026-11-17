# Not in the book: the newest upstream release (GNOME 51), built with its
# meson files (the README gives no build instructions). meson gives cargo a
# home of its own under the build directory and cargo fetches the crates
# there.
build() {
    mkdir build
    cd build
    # --wrap-mode=nodownload: the tarball names GTK and libadwaita as
    # subprojects to fetch when missing.
    # - djvu: needs djvulibre, which has no recipe.
    # - sysprof: needs libsysprof-capture, which has no recipe.
    # - documentation: needs gi-docgen.
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        --wrap-mode=nodownload \
        -D profile=default \
        -D shell=true \
        -D previewer=true \
        -D thumbnailer=true \
        -D nautilus=true \
        -D pdf=enabled \
        -D comics=enabled \
        -D tiff=enabled \
        -D djvu=disabled \
        -D keyring=enabled \
        -D spell_check=enabled \
        -D gtk_unix_print=enabled \
        -D introspection=enabled \
        -D sysprof=disabled \
        -D user_doc=true \
        -D documentation=false \
        -D tests=false \
        -D file_tests=false
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
