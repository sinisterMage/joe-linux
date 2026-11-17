# Not in the book: newest stable CPAN release; following upstream Makefile.PL.
# Vendor paths come from Perl Config (/usr/lib/perl5/5.44/vendor_perl).
build() {
    unset PERL5LIB PERL_MM_OPT PERL_MB_OPT PERL_LOCAL_LIB_ROOT
    export PERL_MM_USE_DEFAULT=1 PERL_AUTOINSTALL=--skipdeps
    # Linux uses glibc obstacks; the upstream -lobstack is for other hosts.
    perl Makefile.PL INSTALLDIRS=vendor NO_PERLLOCAL=1 NO_PACKLIST=1 LIBS=-lpthread
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
