# Not in the book: newest stable CPAN release; following upstream Build.PL.
# Vendor paths come from Perl Config (/usr/lib/perl5/5.44/vendor_perl).
build() {
    unset PERL5LIB PERL_MM_OPT PERL_MB_OPT PERL_LOCAL_LIB_ROOT
    perl Build.PL --installdirs=vendor --create_packlist=0
    perl Build
}

package() {
    perl Build install --destdir="$DESTDIR" --installdirs=vendor --create_packlist=0
}
