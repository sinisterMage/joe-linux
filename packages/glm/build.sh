# The book's GLM page copies the glm directory to /usr/include. This
# installs the same headers through upstream's CMake install target, which
# also installs the CMake package files (usr/share/glm/glmConfig.cmake)
# that find_package(glm) in other projects looks for, and leaves out the
# CMakeLists.txt the plain copy would put into /usr/include/glm.
# GLM_BUILD_LIBRARY=OFF: header-only, as the book has it.
build() {
    mkdir build
    cd build
    cmake -D CMAKE_INSTALL_PREFIX=/usr \
        -D GLM_BUILD_LIBRARY=OFF \
        -D GLM_BUILD_TESTS=OFF \
        -D GLM_BUILD_INSTALL=ON \
        -G Ninja ..
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
