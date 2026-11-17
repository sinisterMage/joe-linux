# Not in the book: the newest upstream release, built with CMake as its
# README says and as Arch Linux builds it. CMake 4 needs the policy
# minimum: the project asks for 3.0.
#
# Users link the reentrant libqhull_r (matplotlib, SciPy, Octave, GDAL).
# The static libraries are shipped because upstream builds libqhullcpp
# only as one, and the installed CMake package (QhullTargets.cmake) refers
# to all of them: removing them would make find_package(Qhull) fail.
build() {
    cmake -B build -G Ninja \
        -D CMAKE_INSTALL_PREFIX=/usr \
        -D CMAKE_BUILD_TYPE=Release \
        -D CMAKE_SKIP_RPATH=ON \
        -D CMAKE_POLICY_VERSION_MINIMUM=3.5
    ninja -C build
}

package() {
    DESTDIR="$DESTDIR" ninja -C build install
}
