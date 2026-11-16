# Not in the book: the newest upstream release, built as the Perl module it
# is (File::StripNondeterminism, with ExtUtils::MakeMaker).
build() {
    # Installed as a vendor module. perllocal.pod and .packlist are shared
    # bookkeeping files that every module would otherwise write to.
    perl Makefile.PL INSTALLDIRS=vendor NO_PERLLOCAL=1 NO_PACKLIST=1
    make
}

package() {
    make DESTDIR="$DESTDIR" install
    # dh_strip_nondeterminism is a debhelper add-on (it loads
    # Debian::Debhelper::Dh_Lib); joe Linux has no debhelper.
    rm -v "$DESTDIR/usr/bin/dh_strip_nondeterminism" \
        "$DESTDIR/usr/share/man/man1/dh_strip_nondeterminism.1"
}
