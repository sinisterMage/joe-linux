# Not in the book: the newest CPAN release, built as its README says.
build() {
    # Installed as a vendor module. perllocal.pod and .packlist are shared
    # bookkeeping files that every module would otherwise write to.
    perl Makefile.PL INSTALLDIRS=vendor NO_PERLLOCAL=1 NO_PACKLIST=1
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
