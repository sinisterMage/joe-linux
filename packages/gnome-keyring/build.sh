prepare() {
    # A deprecated path in the schema template.
    sed -i 's:"/desktop:"/org:' schema/*.xml
}

build() {
    mkdir build-gkr
    cd build-gkr
    # - ssh-agent: off, the upstream default; it wraps OpenSSH's ssh-agent,
    #   which does not exist here.
    # - libcap-ng, selinux: do not exist here. gnome-keyring-daemon is
    #   installed without the cap_ipc_lock file capability (packages never
    #   call setcap), so its secrets may be swapped out when the memory lock
    #   limit is exceeded; it says so in the journal and works.
    # - pam: pam_gnome_keyring.so goes to /usr/lib/security. Adding it to a
    #   PAM service file is up to the display manager.
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        --wrap-mode=nofallback \
        -D pam=true \
        -D systemd=enabled \
        -D ssh-agent=false \
        -D libcap-ng=disabled \
        -D selinux=disabled \
        -D manpage=true
    ninja
}

package() {
    cd build-gkr
    DESTDIR="$DESTDIR" ninja install
}
