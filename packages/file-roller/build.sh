build() {
    mkdir build
    cd build
    # The book's option (packagekit=false: there is no PackageKit), plus
    # the automatic ones stated: the Nautilus "Extract here"/"Compress"
    # actions and libarchive on, cpio by its installed path rather than
    # wherever the build root has it, no introspection data or API
    # reference of the program's internals. use_native_appchooser stays at
    # upstream's default (the portal's chooser only handles one file).
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        --wrap-mode=nofallback \
        -D packagekit=false \
        -D nautilus-actions=enabled \
        -D notification=enabled \
        -D libarchive=enabled \
        -D cpio=/usr/bin/cpio \
        -D use_native_appchooser=false \
        -D introspection=disabled \
        -D api_docs=disabled \
        -D run-in-place=false
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
    # From the book: the script is installed without its execute bit.
    chmod -v 0755 "$DESTDIR/usr/libexec/file-roller/isoinfo.sh"
}
