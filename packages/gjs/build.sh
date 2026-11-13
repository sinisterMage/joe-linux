build() {
    mkdir gjs-build
    cd gjs-build
    # - profiler: needs sysprof, which does not exist here.
    # - The test programs are always compiled, but are neither run nor
    #   installed; skip_gtk_tests and skip_dbus_tests only stop meson from
    #   insisting on GTK and dbus-run-session for tests that never run.
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        --wrap-mode=nofallback \
        -D readline=enabled \
        -D profiler=disabled \
        -D installed_tests=false \
        -D skip_gtk_tests=true \
        -D skip_dbus_tests=true \
        -D dtrace=false \
        -D systemtap=false
    ninja
}

package() {
    cd gjs-build
    DESTDIR="$DESTDIR" ninja install
}
