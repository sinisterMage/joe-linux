# Not in the book: newest stable upstream release, following INSTALL.
# Upstream make install stages translations, desktop entry, AppStream metadata,
# help and icons as well as the executable and Gscan2pdf vendor Perl modules.
build() {
    unset PERL5LIB PERL_MM_OPT PERL_MB_OPT PERL_LOCAL_LIB_ROOT
    export PERL_MM_USE_DEFAULT=1 PERL_AUTOINSTALL=--skipdeps
    perl Makefile.PL PREFIX=/usr INSTALLDIRS=vendor \
        NO_PERLLOCAL=1 NO_PACKLIST=1 \
        SHAREDIR=/usr/share LOCALEDIR=/usr/share/locale
    make
}

package() {
    make DESTDIR="$DESTDIR" install
    install -Dm644 icons/gscan2pdf.svg \
        "$DESTDIR/usr/share/icons/hicolor/scalable/apps/gscan2pdf.svg"
}
