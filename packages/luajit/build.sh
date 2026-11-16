# Following the book's luajit page (its commands), with a newer commit of
# upstream's v2.1 branch than the book's snapshot; see package.zon. The
# luajit program has the VM linked in, as upstream builds it by default;
# libluajit-5.1.so is for programs that embed it.
build() {
    # PREFIX is compiled in: it is where require looks for modules
    # (/usr/share/lua/5.1, /usr/lib/lua/5.1) and for the jit.* modules.
    make PREFIX=/usr amalg
}

package() {
    make PREFIX=/usr DESTDIR="$DESTDIR" install
    # The book's removal: nothing needs the static library.
    rm -v "$DESTDIR/usr/lib/libluajit-5.1.a"
}
