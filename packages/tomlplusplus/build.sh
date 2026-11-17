# Not in the book: the newest upstream release, built with meson as its
# README.md says.
build() {
    # build_lib: compile the implementation into libtomlplusplus.so, as
    # other distributions do, rather than installing headers only; the
    # pkg-config and CMake files then tell users to link it
    # (TOML_HEADER_ONLY=0). Programs can still define TOML_HEADER_ONLY=1 to
    # use the headers alone. cmake is used by meson's cmake module to write
    # the CMake package files.
    meson setup build \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        -D build_lib=true \
        -D build_tests=false \
        -D build_examples=false \
        -D build_tt=false \
        -D generate_cmake_config=true
    ninja -C build
}

package() {
    DESTDIR="$DESTDIR" ninja -C build install
}
