# Not in the book: the newest upstream release, built with meson as its
# README says.
build() {
    mkdir build
    cd build
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        -D profile=default
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
    # The gnomemusic package is installed with install_subdir, which does
    # not byte-compile it, and installed files cannot be written to later.
    local site
    site=$(python3 -c 'import sysconfig; print(sysconfig.get_path("purelib"))')
    python3 -m compileall -q -s "$DESTDIR" -p / "$DESTDIR$site/gnomemusic"
}
