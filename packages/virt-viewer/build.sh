# Not in the book: the newest upstream release (upstream has made none
# since 2021), built with meson as its README says.
prepare() {
    # Current Meson rejects the positional argument this release passes to
    # i18n.merge_file; it only repeated the output file name, which is
    # also given as output:.
    sed -i '/i18n\.merge_file (/{n;/^    [a-z]*,$/d}' data/meson.build
}

build() {
    mkdir build
    cd build
    # oVirt needs libgovirt, which is not packaged.
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        -D libvirt=enabled \
        -D vnc=enabled \
        -D spice=enabled \
        -D ovirt=disabled \
        -D vte=enabled \
        -D bash_completion=enabled \
        -D git_werror=disabled
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
