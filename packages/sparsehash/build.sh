# Not in the book: the newest upstream release (upstream has made none
# since), built as its INSTALL file says. It installs only headers and
# libsparsehash.pc.
#
# The headers use std::allocator<T>::rebind, which C++20 removed, so they
# serve C++17 code (Strawberry, the only user here). make also compiles
# upstream's tests, which are therefore built as C++17 too.
build() {
    ./configure --prefix=/usr --libdir=/usr/lib CXXFLAGS="-O2 -std=gnu++17"
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
