# Not in the book: the newest upstream release, built with meson as its
# README says. Upstream publishes no checksum for the release archive.
prepare() {
    # GitHub's tag archive omits the translations submodule.
    mkdir -p po
    tar -xf "$SOURCES/dialect-po-bd426bd3adc9917429290f4b6da378076ecf7e2e.tar.gz" \
        -C po --strip-components=1 --no-same-owner --no-same-permissions
}

build() {
    mkdir build
    cd build
    # --wrap-mode=nodownload: the tarball names blueprint-compiler as a
    # subproject to fetch when missing.
    meson setup .. \
        --prefix=/usr \
        --buildtype=release \
        --wrap-mode=nodownload \
        -D profile=default
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
