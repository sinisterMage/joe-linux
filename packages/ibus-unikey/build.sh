# Not in the book: the newest upstream release, built with CMake as its
# wiki says.
prepare() {
    # -Werror turns the warnings of newer compilers into failures.
    sed -i 's/ -Werror//' CMakeLists.txt
}

build() {
    # The CMake files predate CMake 3.5. GSETTINGS_COMPILE=OFF: the
    # install step would otherwise run glib-compile-schemas on
    # /usr/share/glib-2.0/schemas itself, outside DESTDIR.
    cmake -B build \
        -D CMAKE_INSTALL_PREFIX=/usr \
        -D CMAKE_INSTALL_LIBEXECDIR=libexec \
        -D CMAKE_BUILD_TYPE=Release \
        -D CMAKE_POLICY_VERSION_MINIMUM=3.5 \
        -D GSETTINGS_COMPILE=OFF \
        -D GSETTINGS_COMPILE_IN_PLACE=OFF
    make -C build
}

package() {
    make -C build DESTDIR="$DESTDIR" install
}
