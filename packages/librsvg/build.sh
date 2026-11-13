build() {
    # Keep cargo's registry and download cache inside the build directory
    # rather than in root's home in the shared build root.
    export CARGO_HOME="$PWD/.cargo-home"

    mkdir build
    cd build
    # pixbuf-loader is off by default upstream, where glycin renders SVG for
    # gdk-pixbuf; joe's gdk-pixbuf is built without glycin, so this module is
    # what lets it (and GTK 3) read SVG. No dav1d for AVIF images embedded in
    # SVG. "docs" only builds the manual page: gi-docgen has no recipe.
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        -D introspection=enabled \
        -D vala=enabled \
        -D pixbuf=enabled \
        -D pixbuf-loader=enabled \
        -D rsvg-convert=enabled \
        -D avif=disabled \
        -D docs=enabled \
        -D tests=false
    ninja
}

package() {
    export CARGO_HOME="$PWD/.cargo-home"
    cd build
    # With DESTDIR set the install script does not run
    # gdk-pixbuf-query-loaders; gdk-pixbuf's trigger does.
    DESTDIR="$DESTDIR" ninja install
}
