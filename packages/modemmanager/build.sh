build() {
    mkdir build
    cd build
    # The book's switches, except QRTR: libqrtr-glib is packaged, so modems
    # built into Qualcomm SoCs are supported. Stated besides: the unit, udev
    # and D-Bus policy directories (vendor policy goes to /usr/share, where
    # this system's D-Bus reads it); polkit in upstream's strict mode;
    # the Vala bindings the book recommends; no examples or tests.
    #
    # ModemManager.service is installed but not enabled, and its
    # dbus-org.freedesktop.ModemManager1.service alias is made only by
    # enabling it. joe-desktop does both.
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        -D systemdsystemunitdir=/usr/lib/systemd/system \
        -D udevdir=/usr/lib/udev \
        -D dbus_policy_dir=/usr/share/dbus-1/system.d \
        -D systemd_suspend_resume=true \
        -D systemd_journal=true \
        -D polkit=strict \
        -D mbim=true \
        -D qmi=true \
        -D qrtr=true \
        -D introspection=true \
        -D vapi=true \
        -D man=true \
        -D bash_completion=false \
        -D gtk_doc=false \
        -D examples=false \
        -D tests=false
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
