# Not in the book: the newest upstream release, built with meson. An
# optional extra, not part of joe-desktop: it installs and updates Flatpak
# applications and device firmware (fwupd). joe's own packages are managed
# by dave, for which gnome-software has no plug-in.
build() {
    mkdir build
    cd build
    # --wrap-mode=nofallback: the tarball names AppStream, libxmlb, GTK,
    # libadwaita, malcontent and sysprof as subprojects to fall back on.
    # Off: PackageKit, Snap, rpm-ostree, eos-updater, the openSUSE and DKMS
    # helpers and systemd-sysupdate (other distributions' update paths),
    # parental controls (malcontent has no recipe), metered-data scheduling
    # (Mogwai), web applications (they install through Epiphany, and the
    # hard-coded lists of them need it), sysprof profiling, the API
    # reference, and the curated and featured lists meant for testing.
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        --wrap-mode=nofallback \
        -D flatpak=true \
        -D fwupd=true \
        -D gudev=true \
        -D polkit=true \
        -D man=true \
        -D packagekit=false \
        -D packagekit_autoremove=false \
        -D snap=false \
        -D rpm_ostree=false \
        -D eos_updater=false \
        -D opensuse-distro-upgrade=false \
        -D dkms=false \
        -D systemd-sysupdate=false \
        -D malcontent=false \
        -D mogwai=false \
        -D webapps=false \
        -D hardcoded_foss_webapps=false \
        -D hardcoded_proprietary_webapps=false \
        -D hardcoded_curated=false \
        -D default_featured_apps=false \
        -D external_appstream=false \
        -D apt=false \
        -D sysprof=disabled \
        -D gtk_doc=false \
        -D tests=false \
        -D installed_tests=false
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
