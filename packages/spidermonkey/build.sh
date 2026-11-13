# mach must not create a virtualenv and pip-install into it: "none" makes it
# use only the Python packages vendored in the tarball (third_party/python).
# Its state directory (normally ~/.mozbuild) is kept inside the build tree.
_mach_env() {
    export MACH_BUILD_PYTHON_NATIVE_PACKAGE_SOURCE=none
    export MOZBUILD_STATE_PATH="$PWD/mozbuild"
}

prepare() {
    patch -Np1 -i "$SOURCES/spidermonkey-140.17.0-python_3.14_fixes-1.patch"

    cat > mozconfig << "EOF2"
ac_add_options --prefix=/usr
ac_add_options --enable-project=js
ac_add_options --disable-debug-symbols
ac_add_options --disable-jemalloc
ac_add_options --enable-readline
ac_add_options --enable-rust-simd
ac_add_options --with-intl-api
ac_add_options --with-system-icu
ac_add_options --with-system-zlib
EOF2
}

build() {
    # Python's multiprocessing, which mach uses, needs a writable /dev/shm.
    mountpoint -q /dev/shm || mount -t tmpfs devshm /dev/shm || [[ -w /dev/shm ]]

    _mach_env
    ./mach build -j"$JOBS"
}

package() {
    _mach_env
    DESTDIR="$DESTDIR" ./mach install

    # The static library is not wanted, and js140-config must not refer to
    # NSPR flags that this build does not have.
    rm -v "$DESTDIR/usr/lib/libjs_static.ajs"
    sed -i '/@NSPR_CFLAGS@/d' "$DESTDIR/usr/bin/js140-config"

    # Users of the headers (gjs) need XP_UNIX defined.
    sed '$i#define XP_UNIX' -i "$DESTDIR/usr/include/mozjs-140/js-config.h"
}
