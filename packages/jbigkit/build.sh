# Not in the book: the newest upstream release. Upstream's Makefiles build
# only static libraries (libjbig.a, libjbig85.a) and the converters in
# pbmtools/, and have no install target; INSTALL says to copy the results.
# As distributions do, the two libraries are built shared here. Upstream
# promises no stable ABI (2.2 changed struct jbg_dec_state from 2.1), so
# the soname carries the full version, as Fedora's does: libjbig.so.2.2,
# libjbig85.so.2.2.
_cflags="-O2 -W -Wall -fPIC"

build() {
    cd libjbig
    for f in jbig jbig85 jbig_ar; do
        gcc $_cflags ${CFLAGS-} -c $f.c -o $f.o
    done
    gcc -shared ${LDFLAGS-} -Wl,-soname,libjbig.so.2.2 -o libjbig.so.2.2 jbig.o jbig_ar.o
    gcc -shared ${LDFLAGS-} -Wl,-soname,libjbig85.so.2.2 -o libjbig85.so.2.2 jbig85.o jbig_ar.o
    ln -sf libjbig.so.2.2 libjbig.so
    ln -sf libjbig85.so.2.2 libjbig85.so
    cd ../pbmtools
    # The converters, linked against the shared libraries above. The
    # Makefile would also archive the static libraries from the same
    # objects first; they are not installed.
    make CFLAGS="$_cflags ${CFLAGS-}" pbmtojbg jbgtopbm pbmtojbg85 jbgtopbm85
}

package() {
    install -d "$DESTDIR/usr/lib" "$DESTDIR/usr/include" "$DESTDIR/usr/bin" \
        "$DESTDIR/usr/share/man/man1"
    install -m755 libjbig/libjbig.so.2.2 libjbig/libjbig85.so.2.2 "$DESTDIR/usr/lib/"
    ln -s libjbig.so.2.2 "$DESTDIR/usr/lib/libjbig.so"
    ln -s libjbig85.so.2.2 "$DESTDIR/usr/lib/libjbig85.so"
    install -m644 libjbig/jbig.h libjbig/jbig85.h libjbig/jbig_ar.h "$DESTDIR/usr/include/"
    install -m755 pbmtools/pbmtojbg pbmtools/jbgtopbm \
        pbmtools/pbmtojbg85 pbmtools/jbgtopbm85 "$DESTDIR/usr/bin/"
    # pbm.5 and pgm.5 describe Netpbm's formats and belong to Netpbm.
    install -m644 pbmtools/pbmtojbg.1 pbmtools/jbgtopbm.1 "$DESTDIR/usr/share/man/man1/"
}
