# Not in the book: the newest upstream release, built with its Makefile as
# its README says (the experimental libnethogs is not built).
build() {
    # The Makefile's default flags have no optimisation. VERSION would
    # otherwise come from git, or from the name of the build directory.
    make nethogs \
        VERSION="$PKG_VERSION" \
        CFLAGS="-O2 -Wall -Wextra" \
        CXXFLAGS="-O2 -Wall -Wextra -Wno-missing-field-initializers -std=c++14" \
        NCURSES_LIBS="$(pkg-config --libs ncursesw)"
}

package() {
    # Installs /usr/sbin/nethogs and its manual page.
    make install \
        PREFIX=/usr \
        VERSION="$PKG_VERSION" \
        CFLAGS="-O2 -Wall -Wextra" \
        CXXFLAGS="-O2 -Wall -Wextra -Wno-missing-field-initializers -std=c++14" \
        NCURSES_LIBS="$(pkg-config --libs ncursesw)" \
        DESTDIR="$DESTDIR"
}
