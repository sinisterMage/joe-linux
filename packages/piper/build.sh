# Not in the book: the newest upstream release, built as its README says.
# 0.8 (2024) is still the newest tag; there are no release tarballs.
build() {
    # The run-time dependency checks look for ratbagd and the Python
    # modules in the build root; the dependencies are declared instead.
    meson setup build \
        --prefix=/usr \
        --buildtype=release \
        --wrap-mode=nodownload \
        -D runtime-dependency-checks=false
    ninja -C build
}

package() {
    DESTDIR="$DESTDIR" ninja -C build install
}
