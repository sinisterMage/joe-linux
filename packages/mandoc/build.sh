# Not in the book: the newest upstream release, built as its INSTALL says,
# with the configure.local settings Debian uses so that mandoc installs
# beside man-db and groff. man-db owns man, apropos, whatis and catman, and
# groff owns soelim and roff(7); man-pages owns man(7). mandoc and demandoc
# keep their names; the others become mman, mapropos, mwhatis, mandocdb
# (makewhatis) and msoelim, and the manual pages that would collide become
# mandoc_man(7), mandoc_mdoc(7), mandoc_roff(7), mandoc_eqn(7) and
# mandoc_tbl(7). man.cgi, catman and the static libmandoc are not built,
# as by default.
build() {
    # configure ignores CFLAGS from the environment; without any it
    # compiles with -g alone. UTF8_LOCALE is glibc's built-in C.UTF-8
    # rather than whatever "locale -a" finds in the build root. Programs
    # are installed in /usr/bin, and the links between them are symbolic.
    cat > configure.local <<'LOCAL'
PREFIX=/usr
BINDIR=/usr/bin
SBINDIR=/usr/bin
BIN_FROM_SBIN=.
MANDIR=/usr/share/man
MANPATH_DEFAULT=/usr/share/man:/usr/local/share/man
MANPATH_BASE=/usr/share/man
UTF8_LOCALE=C.UTF-8
CFLAGS="-g -O2"
LN="ln -sf"
INSTALL_PROGRAM="install -m 0755"
INSTALL_LIB="install -m 0644"
INSTALL_MAN="install -m 0644"
INSTALL_DATA="install -m 0644"
MANM_MANCONF=mandoc.conf
MANM_MAN=mandoc_man
MANM_MDOC=mandoc_mdoc
MANM_ROFF=mandoc_roff
MANM_EQN=mandoc_eqn
MANM_TBL=mandoc_tbl
BINM_MAN=mman
BINM_APROPOS=mapropos
BINM_WHATIS=mwhatis
BINM_MAKEWHATIS=mandocdb
BINM_SOELIM=msoelim
BINM_PAGER=less
LOCAL
    ./configure
    make
}

package() {
    make DESTDIR="$DESTDIR" install

    # mapropos and mwhatis read /usr/share/man/mandoc.db, which mandocdb
    # writes; nothing packages it. Optional, like man-db's own index: a
    # failure to index must never stop a transaction.
    install -d "$DESTDIR/usr/lib/dave/triggers"
    cat > "$DESTDIR/usr/lib/dave/triggers/50-mandoc.zon" <<'TRIGGER'
.{
    .name = "mandoc manual page database",
    .optional = true,
    .paths = .{"usr/share/man/"},
    .exec = .{ "/usr/bin/mandocdb", "/usr/share/man" },
}
TRIGGER
}
