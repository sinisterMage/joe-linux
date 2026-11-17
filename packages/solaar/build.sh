# Not in the book: the newest upstream release, built as a wheel as
# setup.py says (upstream's docs/installation.md).

prepare() {
    # The sdist's udev rule also gives the logged-in user /dev/uinput, so
    # that rules can type and click under Wayland. Upstream's repository
    # keeps that in a separate, opt-in rule (rules.d-uinput) because it
    # lets the user inject input; the default rule, as distributions ship
    # it, only gives access to the Logitech receivers and devices.
    sed -i '/KERNEL=="uinput"/d' rules.d/42-logitech-unify-permissions.rules
}

build() {
    pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps "$PWD"
}

package() {
    # The data files include the udev rule, in /usr/lib/udev/rules.d,
    # which gives the user at the seat access to the receivers (uaccess).
    pip3 install --no-index --no-deps --no-user --ignore-installed --no-warn-script-location \
        --root "$DESTDIR" --find-links dist solaar
    test -f "$DESTDIR/usr/lib/udev/rules.d/42-logitech-unify-permissions.rules"
}
