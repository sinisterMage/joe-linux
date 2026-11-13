build() {
    mkdir build
    cd build
    # The book's options, plus: assembly required rather than detected, no
    # tests, and no xxhash output muxer in the dav1d tool (no recipe).
    meson setup --prefix=/usr --buildtype=release --wrap-mode=nofallback \
        -D enable_asm=true \
        -D enable_tests=false \
        -D enable_docs=false \
        -D xxhash_muxer=disabled \
        ..
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
