# Not in the book: the newest upstream release, built with meson as its
# README says. Every optional part is chosen explicitly. Left out because
# joe has no recipe for what they need: disc burning (libbrasero-media),
# DAAP sharing (libdmapsharing), iPods (libgpod) and LIRC remote controls.
# Vala is only used by the sample plugins, which are not installed. The FM
# radio plugin needs only the kernel's V4L2 headers.
build() {
    mkdir build
    cd build
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        -D brasero=disabled \
        -D daap=disabled \
        -D fm_radio=enabled \
        -D grilo=enabled \
        -D gudev=enabled \
        -D ipod=disabled \
        -D libnotify=enabled \
        -D libsecret=enabled \
        -D lirc=disabled \
        -D mtp=enabled \
        -D plugins_python=enabled \
        -D plugins_vala=disabled \
        -D sample-plugins=false \
        -D help=true \
        -D apidoc=false \
        -D tests=disabled
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
    # The Python plugins are installed as plain data files, which are not
    # byte-compiled, and installed files cannot be written to later.
    python3 -m compileall -q -s "$DESTDIR" -p / "$DESTDIR/usr/lib/rhythmbox/plugins"
}
