# Not in the book: the newest upstream release, built with its Makefile as
# its README says. moreutils' parallel and its manual page are left out:
# /usr/bin/parallel is GNU parallel's (the parallel package).
_make() {
    make PREFIX=/usr \
        BINS="isutf8 ifdata ifne pee sponge mispipe lckdo errno" \
        MANS="sponge.1 vidir.1 vipe.1 isutf8.1 ts.1 combine.1 ifdata.1 ifne.1 pee.1 zrun.1 chronic.1 mispipe.1 lckdo.1 errno.1" \
        DOCBOOKXSL=/usr/share/xml/docbook/xsl-stylesheets-nons-1.79.2 \
        INSTALL_BIN=install \
        "$@"
}

build() {
    _make
}

package() {
    _make DESTDIR="$DESTDIR" install
}
