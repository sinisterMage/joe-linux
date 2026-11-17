# Not in the book: newest upstream release, following its Makefile.
# The release archive contains its locked molinillo dependency as source;
# bootstrapping shards never invokes a binary shards or fetches dependencies.

build() {
    export CRYSTAL_CACHE_DIR="$PWD/.crystal-cache"
    export -n SOURCES
    make release=1 FLAGS=--no-debug
}

package() {
    export -n SOURCES
    make PREFIX=/usr DESTDIR="$DESTDIR" release=1 FLAGS=--no-debug install
    install -Dm644 LICENSE "$DESTDIR/usr/share/licenses/shards/LICENSE"
    install -Dm644 lib/molinillo/LICENSE "$DESTDIR/usr/share/licenses/shards/molinillo-LICENSE"
}
