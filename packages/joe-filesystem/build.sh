package() {
    cd "$DESTDIR"

    # /var and /home are mount points for subvolumes shared by all deployments.
    # They, and the others below, are shipped as plain directories so that
    # systemd-tmpfiles never creates them as nested btrfs subvolumes, which a
    # deployment snapshot would not include.
    install -d dev proc sys run efi home mnt opt srv var etc
    install -d -m 0750 root
    install -d -m 1777 tmp
    install -d usr/{bin,sbin,lib,include,share,src}
    install -d usr/local/{bin,sbin,lib,include,share,src}
    install -d usr/share/{man,misc}
    install -d usr/lib/dave/{db,triggers} etc/dave/keys

    ln -s usr/bin bin
    ln -s usr/sbin sbin
    ln -s usr/lib lib
    # The x86-64 ABI names the dynamic linker /lib64/ld-linux-x86-64.so.2.
    ln -s usr/lib lib64
    ln -s lib usr/lib64

    ln -s ../proc/self/mounts etc/mtab
    printf '127.0.0.1  localhost\n::1        localhost\n' > etc/hosts
    echo joe > etc/hostname
    printf '/bin/sh\n/bin/bash\n' > etc/shells
    # The image builder writes the real table; / is never listed in it.
    : > etc/fstab

    # Accounts have fixed ids: /var is shared between deployments, so an id
    # must mean the same thing in every one of them.
    cat > etc/passwd <<'EOT'
root:x:0:0:root:/root:/bin/bash
bin:x:1:1:bin:/dev/null:/usr/bin/false
daemon:x:6:6:Daemon User:/dev/null:/usr/bin/false
messagebus:x:18:18:D-Bus Message Daemon User:/run/dbus:/usr/bin/false
systemd-journal-gateway:x:73:73:systemd Journal Gateway:/:/usr/bin/false
systemd-journal-remote:x:74:74:systemd Journal Remote:/:/usr/bin/false
systemd-journal-upload:x:75:75:systemd Journal Upload:/:/usr/bin/false
systemd-network:x:76:76:systemd Network Management:/:/usr/bin/false
systemd-resolve:x:77:77:systemd Resolver:/:/usr/bin/false
systemd-timesync:x:78:78:systemd Time Synchronization:/:/usr/bin/false
systemd-coredump:x:79:79:systemd Core Dumper:/:/usr/bin/false
uuidd:x:80:80:UUID Generation Daemon User:/dev/null:/usr/bin/false
systemd-oom:x:81:81:systemd Out Of Memory Daemon:/:/usr/bin/false
systemd-imds:x:82:82:systemd Instance Metadata:/:/usr/bin/false
nobody:x:65534:65534:Unprivileged User:/dev/null:/usr/bin/false
EOT
    cat > etc/group <<'EOT'
root:x:0:
bin:x:1:daemon
sys:x:2:
kmem:x:3:
tape:x:4:
tty:x:5:
daemon:x:6:
floppy:x:7:
disk:x:8:
lp:x:9:
dialout:x:10:
audio:x:11:
video:x:12:
utmp:x:13:
clock:x:14:
cdrom:x:15:
adm:x:16:
messagebus:x:18:
systemd-journal:x:23:
input:x:24:
mail:x:34:
kvm:x:61:
systemd-journal-gateway:x:73:
systemd-journal-remote:x:74:
systemd-journal-upload:x:75:
systemd-network:x:76:
systemd-resolve:x:77:
systemd-timesync:x:78:
systemd-coredump:x:79:
uuidd:x:80:
systemd-oom:x:81:
systemd-imds:x:82:
wheel:x:97:
users:x:999:
nogroup:x:65534:
EOT
    # root has no usable password until one is set.
    awk -F: '{ print $1 ":!:19000:0:99999:7:::" }' etc/passwd > etc/shadow
    awk -F: '{ print $1 ":!::" }' etc/group > etc/gshadow
    chmod 0600 etc/shadow etc/gshadow

    # The login profile is a sealed file: a root shell reads only sealed
    # scripts, so the system's own settings cannot live in editable /etc.
    # What the administrator adds in /etc is read for every other user.
    install -d usr/lib/joe/profile.d etc/profile.d
    cat > usr/lib/joe/profile <<'EOT'
export PATH=/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin
umask 022
if [ "${PS1-}" ]; then PS1='\u@\h:\w\$ '; fi
# Settings shipped by packages: sealed, so read for every user.
for script in /usr/lib/joe/profile.d/*.sh; do
    [ -r "$script" ] && . "$script"
done
unset script
if [ "$(id -u)" -ne 0 ]; then
    [ -r /etc/profile ] && . /etc/profile
    for script in /etc/profile.d/*.sh; do
        [ -r "$script" ] && . "$script"
    done
    unset script
fi
EOT
    # The same for interactive shells that are not login shells.
    cat > usr/lib/joe/bashrc <<'EOT'
PS1='\u@\h:\w\$ '
if [ "$(id -u)" -ne 0 ] && [ -r /etc/bashrc ]; then . /etc/bashrc; fi
EOT
    cat > etc/profile <<'EOT'
# Settings for login shells go here, or in files named /etc/profile.d/*.sh.
#
# These files are read for ordinary users only. A root shell reads only
# sealed scripts, and files you can edit are not sealed.
EOT
}
