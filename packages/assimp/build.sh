# Not in the book: the newest upstream release, built with CMake as its
# Build.md describes: the shared library only, without the assimp command
# line tool, the viewer, samples, tests or documentation.
#
# zlib is the system one (ASSIMP_BUILD_ZLIB=OFF), and with it upstream
# looks for the system minizip through pkg-config; joe's minizip puts its
# headers in /usr/include/minizip, so the two #includes are given that
# directory (as upstream's own Hunter build spells them). The other
# libraries in contrib/ (pugixml, RapidJSON, utfcpp, poly2tri, clipper,
# openddl-parser, Open3DGC, stb_image) stay bundled: upstream can use
# system copies of them only through the Hunter package manager, and its
# exported CMake package would not find them for other projects.
prepare() {
    sed -i 's|#    include <unzip.h>|#    include <minizip/unzip.h>|' code/Common/ZipArchiveIOSystem.cpp
    sed -i 's|#include <unzip.h>|#include <minizip/unzip.h>|' code/AssetLib/IFC/IFCLoader.cpp
}

build() {
    cmake -B build -G Ninja \
        -D CMAKE_INSTALL_PREFIX=/usr \
        -D CMAKE_INSTALL_LIBDIR=lib \
        -D CMAKE_BUILD_TYPE=Release \
        -D CMAKE_SKIP_INSTALL_RPATH=ON \
        -D BUILD_SHARED_LIBS=ON \
        -D ASSIMP_BUILD_ZLIB=OFF \
        -D ASSIMP_BUILD_DRACO=OFF \
        -D ASSIMP_BUILD_ASSIMP_TOOLS=OFF \
        -D ASSIMP_BUILD_SAMPLES=OFF \
        -D ASSIMP_BUILD_TESTS=OFF \
        -D ASSIMP_INSTALL_TESTS=OFF \
        -D ASSIMP_BUILD_DOCS=OFF \
        -D ASSIMP_WARNINGS_AS_ERRORS=OFF \
        -D ASSIMP_IGNORE_GIT_HASH=ON \
        -D ASSIMP_BUILD_USE_CCACHE=OFF \
        -D ASSIMP_HUNTER_ENABLED=OFF
    ninja -C build
}

package() {
    DESTDIR="$DESTDIR" ninja -C build install
}
