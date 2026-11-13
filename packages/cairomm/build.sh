build() {
    mkdir bld
    cd bld
    # The book builds the tests (build-tests=true, boost-shared=true), which
    # need Boost and are never installed; they are left out, as are the
    # examples and the Doxygen documentation.
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        --wrap-mode=nofallback \
        -D maintainer-mode=false \
        -D build-documentation=false \
        -D build-deprecated-api=true \
        -D build-exceptions-api=true \
        -D build-examples=false \
        -D build-tests=false
    ninja
}

package() {
    cd bld
    DESTDIR="$DESTDIR" ninja install
}
