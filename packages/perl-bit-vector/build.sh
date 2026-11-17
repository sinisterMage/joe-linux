# Not in the book: newest stable CPAN release; following upstream Makefile.PL.
# Vendor paths come from Perl Config (/usr/lib/perl5/5.44/vendor_perl).
prepare() {
    # C23 (GCC 16's default) makes false and true keywords with the values
    # ToolBox.h's fallback enum gives them; declare the enum only before C23.
    sed -i 's/^\t#ifndef I_STDBOOL$/\t#if !defined(I_STDBOOL) \&\& !(defined(__STDC_VERSION__) \&\& __STDC_VERSION__ >= 202311L)/' ToolBox.h
    grep -q '__STDC_VERSION__ >= 202311L' ToolBox.h
}

build() {
    unset PERL5LIB PERL_MM_OPT PERL_MB_OPT PERL_LOCAL_LIB_ROOT
    export PERL_MM_USE_DEFAULT=1 PERL_AUTOINSTALL=--skipdeps
    perl Makefile.PL INSTALLDIRS=vendor NO_PERLLOCAL=1 NO_PACKLIST=1
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
