# Not in the book: the newest upstream release, built with meson as its
# README says. Upstream publishes no checksum for the release archive.
prepare() {
    patch -Np1 -i /recipe/queued-loading.patch
}

build() {
    python3 -I /recipe/test_async_loading.py
    mkdir build
    cd build
    # --wrap-mode=nodownload: the tarball names blueprint-compiler as a
    # subproject to fetch when missing. acoustid_api_key keeps upstream's
    # default (the key Ear Tag is registered with at AcoustID).
    meson setup .. \
        --prefix=/usr \
        --buildtype=release \
        --wrap-mode=nodownload \
        -D devel=false \
        -D enable_networked_tests=false
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
