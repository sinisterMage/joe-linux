# Valgrind's README_PACKAGERS: the tools and preload libraries in
# /usr/libexec/valgrind must keep their symbols, or function redirection
# and Valgrind's own stack traces break.
NOSTRIP=1

prepare() {
    # Put the HTML manual straight into --datadir below.
    sed -i 's|/doc/valgrind||' docs/Makefile.in
}

build() {
    # As the book does. --enable-only64bit: gcc is built without multilib,
    # so there is no 32-bit x86 compiler or glibc to build those tools
    # with. No MPI compiler exists, so the MPI wrapper is not built.
    ./configure --prefix=/usr \
        --datadir=/usr/share/doc/valgrind-3.28.0 \
        --enable-only64bit
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
