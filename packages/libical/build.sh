build() {
    mkdir build
    cd build
    # ICU is found and used (it has no switch). Berkeley DB and
    # Java do not exist; the examples and tests are not wanted.
    cmake -D CMAKE_INSTALL_PREFIX=/usr \
        -D CMAKE_BUILD_TYPE=Release \
        -D CMAKE_INSTALL_LIBDIR=lib \
        -D LIBICAL_STATIC=NO \
        -D LIBICAL_BUILD_DOCS=false \
        -D LIBICAL_GLIB=true \
        -D LIBICAL_GLIB_BUILD_DOCS=false \
        -D LIBICAL_GLIB_VAPI=true \
        -D LIBICAL_GOBJECT_INTROSPECTION=true \
        -D LIBICAL_JAVA_BINDINGS=OFF \
        -D LIBICAL_BUILD_TESTING=false \
        -D LIBICAL_BUILD_EXAMPLES=false \
        -D CMAKE_DISABLE_FIND_PACKAGE_BerkeleyDB=ON \
        ..
    # The generated sources are not safe to build in parallel.
    make -j1
}

package() {
    cd build
    make DESTDIR="$DESTDIR" install
}
