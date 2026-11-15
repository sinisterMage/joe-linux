# Not in the book: the newest upstream release, built as its README says.
# What is installed is stated rather than guessed from the build root:
# wg-quick, its wg-quick@.service and wg-quick.target (not enabled), and
# the bash completions.
_wg_make() {
    make -C src \
        PREFIX=/usr \
        SYSCONFDIR=/etc \
        RUNSTATEDIR=/run \
        SYSTEMDUNITDIR=/usr/lib/systemd/system \
        WITH_WGQUICK=yes \
        WITH_SYSTEMDUNITS=yes \
        WITH_BASHCOMPLETION=yes \
        "$@"
}

build() {
    _wg_make
}

package() {
    _wg_make DESTDIR="$DESTDIR" install
}
