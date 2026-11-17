# Not in the book: the newest upstream release, built with CMake as its
# README says.
build() {
    # Switched off because joe has no recipe for what they need: OpenCC
    # (chttrans then converts with its built-in table), Qt WebEngine (the
    # dictionary manager's browser for online dictionaries) and
    # fcitx5-lua (Lua extensions to pinyin, which configure looks for
    # without a switch).
    cmake -B build -G Ninja \
        -D CMAKE_INSTALL_PREFIX=/usr \
        -D CMAKE_INSTALL_LIBDIR=lib \
        -D CMAKE_BUILD_TYPE=Release \
        -D ENABLE_TEST=OFF \
        -D ENABLE_OPENCC=OFF \
        -D ENABLE_GUI=ON \
        -D ENABLE_BROWSER=OFF \
        -D ENABLE_CLOUDPINYIN=ON \
        -D ENABLE_DATA=ON \
        -D ENABLE_TOOLS=ON
    ninja -C build
}

package() {
    DESTDIR="$DESTDIR" ninja -C build install
}
