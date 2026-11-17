# Not in the book: the newest upstream release, built with meson as its
# README says.
build() {
    mkdir build
    cd build
    # The tests and the fuzzing targets are never installed.
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        -D tools=enabled \
        -D tests=disabled \
        -D fuzzing=disabled \
        -D git_werror=disabled
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
