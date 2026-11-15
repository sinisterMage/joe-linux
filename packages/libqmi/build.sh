build() {
    mkdir build
    cd build
    # The book's switches, except QRTR: libqrtr-glib is packaged, so QMI
    # over QRTR (modems built into Qualcomm SoCs) is on. QMI over MBIM uses
    # libmbim. The manual pages need help2man.
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        -D introspection=true \
        -D udev=true \
        -D mbim_qmux=true \
        -D qrtr=true \
        -D bash_completion=false \
        -D gtk_doc=false \
        -D man=false
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
