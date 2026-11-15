# The older series of libsigc++, which the GTK 3 C++ bindings (glibmm-2.4 to
# gtkmm-3.0) are built on. Everything it installs carries the 2.0 API
# version (sigc++-2.0), so it does not collide with libsigcxx (sigc++-3.0).
prepare() {
    # From the book: do not ask for Boost's "system" module, which newer
    # Boost releases no longer have (only the benchmark, not built here,
    # would use it).
    sed -i "s/'system',//" meson.build
}

build() {
    mkdir bld
    cd bld
    # The book builds with the defaults. Stated here: no documentation
    # (Doxygen does not exist), and neither the examples nor the tests, which
    # are only compiled, never installed.
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        --wrap-mode=nofallback \
        -D maintainer-mode=false \
        -D build-documentation=false \
        -D build-deprecated-api=true \
        -D validation=false \
        -D build-pdf=false \
        -D build-examples=false \
        -D build-tests=false \
        -D benchmark=false
    ninja
}

package() {
    cd bld
    DESTDIR="$DESTDIR" ninja install
}
