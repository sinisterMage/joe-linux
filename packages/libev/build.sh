# Not in the book: the newest upstream release (4.33 is still the latest),
# built as its README says.
build() {
    ./configure --prefix=/usr \
        --libdir=/usr/lib \
        --disable-static
    make
}

package() {
    make DESTDIR="$DESTDIR" install
    # event.h is libev's libevent compatibility header, and libevent ships
    # the real one at the same path. Other distributions drop libev's.
    rm "$DESTDIR/usr/include/event.h"
}
