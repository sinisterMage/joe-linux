# Not in the book: the newest upstream release, built with meson as
# PACKAGING.md describes.
build() {
    mkdir build
    cd build
    # packagekit: installing missing tools at run time needs PackageKit,
    # which does not exist here. The command options keep their defaults,
    # bare names looked up in PATH.
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        --wrap-mode=nodownload \
        -D packagekit=disabled
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
