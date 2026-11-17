# Not in the book: the newest upstream release, built with CMake as its
# INSTALL says, as Arch builds it: the LV2 plugins without their GTK 2
# interfaces (joe has no GTK 2), so hosts show generic controls. Without a
# GUI there is no calfjackhost, so JACK and LASH are not used either.

prepare() {
    # At configure time CMake deletes the .ttl files of an installed Calf
    # (in the build root, not the staging tree), which a build must not
    # touch; the install step writes fresh ones into $DESTDIR anyway.
    sed -i '/# Remove previous .ttl files/,/endforeach()/d' src/CMakeLists.txt
}

build() {
    # WANT_SORDI only checks the generated Turtle files with sordi.
    cmake -B build -G Ninja \
        -D CMAKE_INSTALL_PREFIX=/usr \
        -D CMAKE_INSTALL_LIBDIR=lib \
        -D CMAKE_BUILD_TYPE=Release \
        -D WANT_GUI=OFF \
        -D WANT_LV2=ON \
        -D WANT_LV2_GUI=OFF \
        -D WANT_JACK=OFF \
        -D WANT_LASH=OFF \
        -D WANT_SORDI=OFF \
        -D WANT_SSE=OFF \
        -D WANT_EXPERIMENTAL=OFF
    ninja -C build
}

package() {
    DESTDIR="$DESTDIR" cmake --install build
    # The manual page and bash completion of calfjackhost, which is not built.
    rm "$DESTDIR/usr/share/man/man1/calfjackhost.1" \
        "$DESTDIR/usr/share/bash-completion/completions/calf"
}
