# Not in the book: the newest upstream release, built with CMake as its
# README.build says.
prepare() {
    # Upstream picks lib64 on Linux unless it sees Debian or Arch.
    sed -i 's|set ( LIB_SUFFIX 64 )|set ( LIB_SUFFIX "" )|' CMakeLists.txt
    # Upstream's fix after 1.5 (commit cdb28383, "fix paths when FTDIPP is
    # set"): with the C++ binding on, libftdi1.pc otherwise points at
    # include/libftdipp1, where ftdi.h is not.
    sed -i 's/project(libftdipp1 C CXX)/project(libftdi1 C CXX)/' CMakeLists.txt

    # Upstream's udev rule, as Arch installs it: the plugdev group it names
    # does not exist on joe, so the logged-in user gets the devices through
    # uaccess instead, which only works before 73-seat-late.rules (hence
    # 69- rather than 99-).
    sed -i 's|MODE="0664", GROUP="plugdev"|TAG+="uaccess"|g' packages/99-libftdi.rules
}

build() {
    # The Python binding (swig) is not built; the example programs and
    # the static libraries are not wanted.
    cmake -B build -G Ninja \
        -D CMAKE_INSTALL_PREFIX=/usr \
        -D CMAKE_BUILD_TYPE=Release \
        -D CMAKE_POLICY_VERSION_MINIMUM=3.5 \
        -D CMAKE_SKIP_INSTALL_RPATH=ON \
        -D STATICLIBS=OFF \
        -D EXAMPLES=OFF \
        -D DOCUMENTATION=OFF \
        -D BUILD_TESTS=OFF \
        -D FTDIPP=ON \
        -D FTDI_EEPROM=ON \
        -D PYTHON_BINDINGS=OFF \
        -D LINK_PYTHON_LIBRARY=OFF
    cmake --build build
}

package() {
    DESTDIR="$DESTDIR" cmake --install build
    install -Dm644 packages/99-libftdi.rules "$DESTDIR/usr/lib/udev/rules.d/69-libftdi.rules"
}
