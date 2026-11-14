# mach must not create a virtualenv and pip-install into it: "none" makes it
# use only the Python packages vendored in the tarball (third_party/python).
# Its state directory (normally ~/.mozbuild) is kept inside the build tree.
_mach_env() {
    export MACH_BUILD_PYTHON_NATIVE_PACKAGE_SOURCE=none
    export MOZBUILD_STATE_PATH="$PWD/mozbuild"
}

prepare() {
    # The book's mozconfig, with these differences:
    # - no Google location service key: the book's key is specific to LFS.
    #   Geolocation goes through GeoClue when that is installed;
    # - --disable-bootstrap: never download toolchains;
    # - cairo-gtk3-wayland instead of the default cairo-gtk3: the Wayland
    #   backend is required and the X11 one is built as well because its
    #   libraries are present. At run time Wayland is used whenever
    #   WAYLAND_DISPLAY is set, X11 (Xwayland) otherwise;
    # - --with-system-ffi and --with-system-pixman: this version no longer
    #   accepts the book's --enable-system-* spellings.
    # Audio is the book's default, PulseAudio (libpulse is loaded at run
    # time; in a joe session the server is PipeWire's pulse front end).
    # Like the book, this does not turn on link-time or profile-guided
    # optimisation.
    cat > mozconfig << "EOF2"
ac_add_options --disable-bootstrap
ac_add_options --disable-necko-wifi

ac_add_options --with-system-av1
ac_add_options --with-system-icu
ac_add_options --with-system-libevent
ac_add_options --with-system-libvpx
ac_add_options --with-system-nspr
ac_add_options --with-system-nss
ac_add_options --with-system-webp

# Mozilla's own unofficial branding (it calls itself "Nightly"), not the
# Firefox name and logo: Mozilla's trademark policy restricts distributing
# builds under those (THIRD-PARTY-NOTICES.md).
ac_add_options --with-branding=browser/branding/unofficial
ac_add_options --disable-debug-symbols

ac_add_options --prefix=/usr
ac_add_options --enable-application=browser
ac_add_options --enable-default-toolkit=cairo-gtk3-wayland
ac_add_options --disable-crashreporter
ac_add_options --disable-updater
ac_add_options --disable-tests
ac_add_options --enable-rust-simd

ac_add_options --with-system-ffi
ac_add_options --with-system-pixman

ac_add_options --with-system-jpeg
ac_add_options --with-system-png
ac_add_options --with-system-zlib

# Sandboxed wasm libraries would need a wasm32-wasi toolchain.
ac_add_options --without-wasm-sandboxed-libraries

# No telemetry.
unset MOZ_TELEMETRY_REPORTING

mk_add_options MOZ_OBJDIR=@TOPSRCDIR@/firefox-build-dir

# The window class and Wayland application id become "firefox", matching
# StartupWMClass in the desktop entry.
MOZ_APP_REMOTINGNAME=firefox
EOF2

    # The book's fix for building with clang 23 or newer.
    sed '/type-limits/a #pragma GCC diagnostic ignored "-Wunused-template"' \
        -i gfx/harfbuzz/src/hb.hh
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

    # Updates come from the package manager, and the browser should not ask
    # to be made the default one. Nothing else is decided for the user.
    install -d "$DESTDIR/usr/lib/firefox/distribution"
    cat > "$DESTDIR/usr/lib/firefox/distribution/policies.json" << "EOF2"
{
  "policies": {
    "DisableAppUpdate": true,
    "DontCheckDefaultBrowser": true
  }
}
EOF2

    install -d "$DESTDIR/usr/share/applications" "$DESTDIR/usr/share/pixmaps"
    cat > "$DESTDIR/usr/share/applications/firefox.desktop" << "EOF2"
[Desktop Entry]
Encoding=UTF-8
Name=Web Browser
Comment=Browse the World Wide Web (Mozilla's browser, without the Firefox name)
GenericName=Web Browser
Exec=firefox %u
Terminal=false
Type=Application
Icon=firefox
Categories=GNOME;GTK;Network;WebBrowser;
MimeType=text/xml;text/mml;text/html;application/xhtml+xml;application/vnd.mozilla.xul+xml;x-scheme-handler/http;x-scheme-handler/https;
StartupNotify=true
StartupWMClass=firefox
EOF2

    # The book's icon, plus the same images in the icon theme so that the
    # shell has a size that fits.
    ln -sfv /usr/lib/firefox/browser/chrome/icons/default/default128.png \
        "$DESTDIR/usr/share/pixmaps/firefox.png"
    local s
    for s in 16 32 48 64 128; do
        install -d "$DESTDIR/usr/share/icons/hicolor/${s}x${s}/apps"
        ln -sv "/usr/lib/firefox/browser/chrome/icons/default/default$s.png" \
            "$DESTDIR/usr/share/icons/hicolor/${s}x${s}/apps/firefox.png"
    done
    install -Dm644 browser/branding/unofficial/default256.png \
        "$DESTDIR/usr/share/icons/hicolor/256x256/apps/firefox.png"
}
