prepare() {
    # pkg_resources is gone from setuptools; the script only needs a version
    # parser.
    sed -e 's/pkg_resources/packaging.version/' \
        -e 's/parse_version/parse/g' \
        -i contrib/generate-version-script.py
}

build() {
    mkdir build
    cd build
    # usb.ids comes from hwdata. gi-docgen and umockdev do not exist.
    meson setup .. \
        --prefix=/usr \
        --buildtype=release \
        -D usb_ids=/usr/share/hwdata/usb.ids \
        -D introspection=true \
        -D vapi=true \
        -D docs=false \
        -D tests=false \
        -D umockdev=disabled
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
