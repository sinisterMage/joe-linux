# Not in the book: the newest upstream release, built as its README says.
# 0.18 (2024) is still the newest tag; there are no release tarballs.
prepare() {
    # The SWIG interfaces (for the uninstalled ratbag-command tool) use the
    # Python 2 PyInt_* calls; SWIG no longer defines them as PyLong_* for
    # Python 3, so use the Python 3 names directly.
    sed -i 's/PyInt_/PyLong_/g' src/libratbag.i src/hidpp.i
    [[ $(cat src/libratbag.i src/hidpp.i | grep -c PyInt_) == 0 ]]
}

build() {
    # - ratbagd.service is installed but not enabled. ratbagd is started
    #   on demand: its D-Bus service file names the unit (SystemdService=),
    #   which systemd starts when Piper or ratbagctl first calls it.
    # - Every user may use ratbagd, as upstream defaults (-D dbus-group
    #   would restrict it to one group).
    # - The tests need check and valgrind and are not built.
    meson setup build \
        --prefix=/usr \
        --libdir=lib \
        --sbindir=sbin \
        --buildtype=release \
        --wrap-mode=nodownload \
        -D systemd=true \
        -D logind-provider=systemd \
        -D systemd-unit-dir=/usr/lib/systemd/system \
        -D documentation=false \
        -D tests=false
    ninja -C build
}

package() {
    DESTDIR="$DESTDIR" ninja -C build install
}
