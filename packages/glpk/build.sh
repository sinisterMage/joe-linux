# Not in the book: the newest upstream release, built as its INSTALL says,
# with GMP for exact arithmetic as Arch Linux builds it. The MathProg
# database tables (ODBC, MySQL) stay off, as upstream defaults.
build() {
    # GLPK 5.0's MiniSat uses an int typedef for bool; preserve its pre-C23
    # GNU C dialect rather than changing the solver's types or hiding errors.
    CFLAGS="${CFLAGS:--O2 -g} -std=gnu17" ./configure --prefix=/usr \
        --disable-static \
        --with-gmp \
        --disable-odbc \
        --disable-mysql
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
