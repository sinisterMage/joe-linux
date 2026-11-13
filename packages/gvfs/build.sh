build() {
    mkdir build
    cd build
    # Every backend is stated, so that the build root cannot change the
    # result. Unlike the book, fuse and goa are on: fuse3 and
    # gnome-online-accounts exist here.
    #
    # On: admin (admin://, through polkit; members of `wheel` are not asked
    # again within a session), archive (deprecated upstream but still
    # shipped; libarchive exists), goa, http (http and dav, libsoup), sftp
    # (runs openssh's ssh at run time), udisks2 and gudev (removable media),
    # fuse (~/.gvfs-style access under /run/user/UID/gvfs for programs that
    # do not use GIO), gcr and keyring (certificates, saved passwords),
    # logind, libusb. Always built: trash, recent, computer, network, burn,
    # ftp, localtest.
    #
    # Off, for lack of a recipe for the library each needs: afc
    # (libimobiledevice), bluray (libbluray), cdda (libcdio-paranoia), dnssd
    # (avahi), gphoto2 (libgphoto2), mtp (libmtp), nfs (libnfs), onedrive
    # (msgraph), smb (samba), wsdd (the wsdd daemon), google (libgdata,
    # deprecated). afp is deprecated and gcrypt only serves afp.
    # man: would need the DocBook stylesheets at build time.
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        --wrap-mode=nofallback \
        -D systemduserunitdir=/usr/lib/systemd/user \
        -D tmpfilesdir=/usr/lib/tmpfiles.d \
        -D privileged_group=wheel \
        -D busy_processes_command=lsof \
        -D admin=true \
        -D archive=true \
        -D goa=true \
        -D http=true \
        -D sftp=true \
        -D udisks2=true \
        -D gudev=true \
        -D fuse=true \
        -D gcr=true \
        -D keyring=true \
        -D logind=true \
        -D libusb=true \
        -D afc=false \
        -D afp=false \
        -D bluray=false \
        -D cdda=false \
        -D dnssd=false \
        -D gcrypt=false \
        -D google=false \
        -D gphoto2=false \
        -D mtp=false \
        -D nfs=false \
        -D onedrive=false \
        -D smb=false \
        -D wsdd=false \
        -D devel_utils=false \
        -D installed_tests=false \
        -D unit_tests=false \
        -D man=false
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
