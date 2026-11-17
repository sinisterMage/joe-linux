# Following the book's v4l-utils page. Switched off: the BPF decoders for
# infrared remotes (they need libbpf, which joe does not package; the book's
# sed as well as the meson option), the gconv modules (as the book does),
# the Doxygen documentation, and the Qt test programs qv4l2 and qvidcap,
# which would make every user of libv4l2 depend on Qt.
prepare() {
    sed -i '/^ir_bpf_enabled/s/=.*/= false/' utils/keytable/meson.build
}

build() {
    mkdir build
    cd build
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        -D gconv=disabled \
        -D doxygen-doc=disabled \
        -D bpf=disabled \
        -D qv4l2=disabled \
        -D qvidcap=disabled \
        -D jpeg=enabled \
        -D libdvbv5=enabled \
        -D v4l2-tracer=enabled
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
    # The book also copies contrib/test/v4l2gl, which is only built with
    # GLU (no recipe).
    install -m755 contrib/test/v4l2grab "$DESTDIR/usr/bin/"
}
