# Not in the book: the newest upstream release, built with its own Makefile
# as its README says.

prepare() {
    # -march=native would tie the library to the build machine's processor.
    # The install step runs ldconfig, which would rewrite the build root's
    # cache; it is replaced by the soname link ldconfig would have made.
    sed -i -e '/-march=native/d' \
        -e 's/^\tldconfig$/\tln -sf $(ZITA-CONVOLVER_MIN) $(DESTDIR)$(LIBDIR)\/$(ZITA-CONVOLVER_MAJ)/' \
        source/Makefile
}

build() {
    make -C source PREFIX=/usr
}

package() {
    # SUFFIX would otherwise be 64 on x86_64, giving /usr/lib64.
    make -C source PREFIX=/usr SUFFIX= DESTDIR="$DESTDIR" install
}
