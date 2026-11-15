# Not in the book (its "pax" page is a different program, the archiver):
# the newest upstream release, configured as Gentoo's ebuild does. The
# SHA-512 in Gentoo's Manifest was checked.
prepare() {
    # joe Linux has no "python" command, only python3.
    sed -i '1s|^#!/usr/bin/env python$|#!/usr/bin/env python3|' lddtree.py
}

build() {
    # The manual pages come ready-made in the tarball; regenerating them
    # needs xmlto, which joe Linux does not have.
    meson setup build \
        --prefix=/usr \
        --buildtype=release \
        -D lddtree_implementation=python \
        -D use_libcap=enabled \
        -D use_seccomp=true \
        -D build_manpages=disabled \
        -D tests=false \
        -D use_fuzzing=false
    ninja -C build
}

package() {
    DESTDIR="$DESTDIR" ninja -C build install
}
