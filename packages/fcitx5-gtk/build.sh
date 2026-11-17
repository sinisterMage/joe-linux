# Not in the book: the newest upstream release, built with CMake as its
# README says.
build() {
    # GTK 2 has no recipe. FcitxG's introspection data is built.
    cmake -B build -G Ninja \
        -D CMAKE_INSTALL_PREFIX=/usr \
        -D CMAKE_INSTALL_LIBDIR=lib \
        -D CMAKE_BUILD_TYPE=Release \
        -D ENABLE_GIR=ON \
        -D ENABLE_GTK2_IM_MODULE=OFF \
        -D ENABLE_GTK3_IM_MODULE=ON \
        -D ENABLE_GTK4_IM_MODULE=ON
    ninja -C build
}

package() {
    DESTDIR="$DESTDIR" ninja -C build install
}
