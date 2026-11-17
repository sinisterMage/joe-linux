# Not in the book: the newest upstream release (1.17), built with its own
# Makefile as doc/installation.html says. Hosts look for plugins in
# /usr/lib/ladspa (or $LADSPA_PATH).

prepare() {
    # -Werror turns whatever a newer compiler warns about into a failed
    # build. The example plugins call sin() and friends without linking
    # libm, as Arch also fixes.
    sed -i -e 's/ -Wall -Werror -O2 / -Wall -O2 /' \
        -e 's/^\t\t-shared\t*\\$/\t\t-shared -lm\t\t\t\t\t\t\\/' \
        src/Makefile
}

build() {
    # "targets": the Makefile's first target runs the examples on a sound
    # file and plays the result.
    make -C src targets
}

package() {
    make -C src \
        INSTALL_PLUGINS_DIR="$DESTDIR/usr/lib/ladspa/" \
        INSTALL_INCLUDE_DIR="$DESTDIR/usr/include/" \
        INSTALL_BINARY_DIR="$DESTDIR/usr/bin/" \
        install
}
