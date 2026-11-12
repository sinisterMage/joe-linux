#!/bin/bash
# Stage 2 of the joe Linux bootstrap: inside the build root produced by stage 1,
# create the basic directory layout and build the last few temporary tools
# that could not be cross-compiled (LFS chapter 7).
#
# After this the build root can build real packages with `dave build`. Like
# stage 1, nothing made here ships.
set -euo pipefail

top=$(cd "$(dirname "$0")/.." && pwd)
root=$top/build/bootstrap/root
done_dir=$top/build/bootstrap/done
logs=$top/build/bootstrap/logs
enter=$top/bootstrap/enter.sh

[[ -e $done_dir/gcc-pass2 ]] || { echo "run stage1.sh first" >&2; exit 1; }
mkdir -p "$root"/{dev,proc,sys,run,tmp,build,sources}

# step <name> <tarball> <shell commands run in the unpacked source, in the build root>
step() {
    local name=$1 tarball=$2 commands=$3
    [[ -e $done_dir/$name ]] && return 0
    echo "==> $name"
    local dir=/build/$name
    if ! "$enter" /usr/bin/bash -euc "
        rm -rf $dir && mkdir -p $dir && cd $dir
        ${tarball:+tar -xf /sources/$tarball --strip-components=1 --no-same-owner}
        $commands
        cd / && rm -rf $dir
    " > "$logs/$name.log" 2>&1; then
        echo "FAILED: $name (see $logs/$name.log)" >&2
        tail -n 30 "$logs/$name.log" >&2
        exit 1
    fi
    touch "$done_dir/$name"
}

# Directories and files every build expects. In the finished system these come
# from the joe-filesystem package; here they only make the build root usable.
step layout "" '
    mkdir -p /{boot,home,mnt,opt,srv} /etc/opt /usr/{,local/}{include,src} /usr/lib/locale
    mkdir -p /usr/local/{bin,lib,sbin} /usr/{,local/}share/{doc,info,locale,man,misc,terminfo,zoneinfo}
    mkdir -p /usr/{,local/}share/man/man{1..8} /var/{cache,local,log,mail,opt,spool,lib,tmp} /root
    ln -sfn /run /var/run
    ln -sfn /run/lock /var/lock
    chmod 0750 /root
    chmod 1777 /var/tmp
    ln -sfn /proc/self/mounts /etc/mtab
    printf "127.0.0.1  localhost\n::1        localhost\n" > /etc/hosts
    cat > /etc/passwd <<"EOT"
root:x:0:0:root:/root:/bin/bash
bin:x:1:1:bin:/dev/null:/usr/bin/false
daemon:x:6:6:Daemon User:/dev/null:/usr/bin/false
nobody:x:65534:65534:Unprivileged User:/dev/null:/usr/bin/false
EOT
    cat > /etc/group <<"EOT"
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
input:x:24:
mail:x:34:
kvm:x:61:
wheel:x:97:
users:x:999:
nogroup:x:65534:
EOT
'

step gettext gettext-1.0.tar.xz '
    ./configure --disable-shared
    make
    cp gettext-tools/src/{msgfmt,msgmerge,xgettext} /usr/bin
'

step bison bison-3.8.2.tar.xz '
    ./configure --prefix=/usr --docdir=/usr/share/doc/bison-3.8.2
    make
    make install
'

step perl perl-5.44.0.tar.xz '
    sh Configure -des -D prefix=/usr -D vendorprefix=/usr -D useshrplib \
        -D privlib=/usr/lib/perl5/5.44/core_perl -D archlib=/usr/lib/perl5/5.44/core_perl \
        -D sitelib=/usr/lib/perl5/5.44/site_perl -D sitearch=/usr/lib/perl5/5.44/site_perl \
        -D vendorlib=/usr/lib/perl5/5.44/vendor_perl -D vendorarch=/usr/lib/perl5/5.44/vendor_perl
    make
    make install
'

step python Python-3.15.2.tar.xz '
    ./configure --prefix=/usr --enable-shared --without-ensurepip --without-static-libpython
    make
    make install
'

step texinfo texinfo-7.3.tar.xz '
    ./configure --prefix=/usr
    make
    make install
'

step util-linux util-linux-2.42.4.tar.xz '
    mkdir -p /var/lib/hwclock
    ./configure --libdir=/usr/lib --runstatedir=/run --disable-chfn-chsh --disable-login \
        --disable-nologin --disable-su --disable-setpriv --disable-runuser \
        --disable-pylibmount --disable-static --disable-liblastlog2 --without-python \
        --disable-makeinstall-chown --disable-makeinstall-setuid \
        ADJTIME_PATH=/var/lib/hwclock/adjtime
    make
    make install
'

# The cross toolchain has done its job; everything now builds natively.
step cleanup "" '
    rm -rf /usr/share/{info,man,doc}/*
    find /usr/{lib,libexec} -name "*.la" -delete
    rm -rf /tools
    # Cross-compilation hints left by stage 1 would mislead native configure runs.
    rm -f /usr/share/config.site
'

echo "stage 2 complete: the build root is ready for dave build"
