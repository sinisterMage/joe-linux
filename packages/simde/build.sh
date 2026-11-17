# Not in the book: the newest upstream release (0.8.4 has had release
# candidates only). SIMDe is headers only; its meson build installs them
# with simde.pc. The test suite is not configured, and SLEEF (no recipe)
# stays off.
build() {
    meson setup build \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        -D tests=false \
        -D sleef=disabled
}

package() {
    DESTDIR="$DESTDIR" ninja -C build install
}
