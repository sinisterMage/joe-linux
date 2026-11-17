# Not in the book: the newest upstream release (the maintained Codeberg
# fork of Google's gumbo), built with meson as its README.md says.
build() {
    # Only the shared library: upstream defaults to both. No tests (they
    # need googletest), examples, fuzzers or the ctypes Python binding.
    meson setup build \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        -D default_library=shared \
        -D tests=false \
        -D examples=false \
        -D fuzz=false \
        -D python=false
    ninja -C build
}

package() {
    DESTDIR="$DESTDIR" ninja -C build install
}
