# The Makefile guesses /lib64 and /usr/lib64 on x86-64 and writes the guess
# into libkeyutils.pc, so the directories are given to both steps.
_dirs="NO_ARLIB=1 LIBDIR=/usr/lib USRLIBDIR=/usr/lib BINDIR=/usr/bin SBINDIR=/usr/sbin"

build() {
    make $_dirs
}

package() {
    make $_dirs DESTDIR="$DESTDIR" install
}
