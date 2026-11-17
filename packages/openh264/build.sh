# Not in the book: the newest upstream release, built from source with its
# meson build files (the library, its headers and openh264.pc; the
# h264enc/h264dec console programs are built but not installed). The tests
# would need googletest from a wrap.
#
# Patents: Cisco pays the MPEG LA licence for H.264 only on the binaries it
# builds and distributes itself (https://www.openh264.org/BINARY_LICENSE.txt);
# a library built from source, as here, is not covered by it. The source
# code is BSD-2-Clause. joe Linux already ships x264 and x265 on the same
# terms, so this follows that decision.
build() {
    # Upstream owns build/; keep Meson's output separate.
    mkdir builddir
    cd builddir
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        --wrap-mode=nofallback \
        -D tests=disabled
    ninja
}

package() {
    cd builddir
    DESTDIR="$DESTDIR" ninja install
}
