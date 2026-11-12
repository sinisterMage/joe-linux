#!/bin/bash
# Stage 1 of the joe Linux bootstrap: a cross toolchain and a minimal set of
# temporary tools, built by this machine's compiler into build/bootstrap/root.
#
# This follows chapters 5 and 6 of Linux From Scratch (systemd, development
# branch r13.1) with the same package versions. Nothing built here ships:
# these tools exist only to build the real packages in packages/, after which
# every one of them has been replaced.
#
# Runs as an ordinary user. Each step leaves a marker, so the script can be
# re-run after a failure and continues where it stopped.
set -euo pipefail

top=$(cd "$(dirname "$0")/.." && pwd)
src=$top/build/src
LFS=$top/build/bootstrap/root
work=$top/build/bootstrap/work
done_dir=$top/build/bootstrap/done
logs=$top/build/bootstrap/logs
LFS_TGT=x86_64-joe-linux-gnu

# A clean, predictable environment, as the book prescribes.
if [[ -z ${JOE_BOOTSTRAP_ENV:-} ]]; then
    exec env -i JOE_BOOTSTRAP_ENV=1 HOME="$HOME" TERM="${TERM:-dumb}" \
        PATH="$LFS/tools/bin:/usr/bin" LC_ALL=POSIX \
        MAKEFLAGS="-j$(nproc)" CONFIG_SITE="$LFS/usr/share/config.site" \
        /bin/bash "$0" "$@"
fi
set +h
umask 022
export LFS LFS_TGT

mkdir -p "$work" "$done_dir" "$logs" "$LFS"/{etc,var,tools,lib64} "$LFS"/usr/{bin,lib,sbin}
for i in bin lib sbin; do
    [[ -e $LFS/$i ]] || ln -s usr/$i "$LFS/$i"
done

# step <name> <tarball> <function>: unpack, build in a fresh directory, record.
step() {
    local name=$1 tarball=$2 fn=$3
    [[ -e $done_dir/$name ]] && return 0
    echo "==> $name"
    rm -rf "$work/$name"
    mkdir -p "$work/$name"
    tar -xf "$src/$tarball" -C "$work/$name" --strip-components=1
    if ! (cd "$work/$name" && set -e && $fn) > "$logs/$name.log" 2>&1; then
        echo "FAILED: $name (see $logs/$name.log)" >&2
        tail -n 30 "$logs/$name.log" >&2
        exit 1
    fi
    rm -rf "$work/$name"
    touch "$done_dir/$name"
}

gcc_prereqs() {
    mkdir mpfr gmp mpc
    tar -xf "$src/mpfr-4.2.2.tar.xz" -C mpfr --strip-components=1
    tar -xf "$src/gmp-6.3.0.tar.xz" -C gmp --strip-components=1
    tar -xf "$src/mpc-1.4.1.tar.xz" -C mpc --strip-components=1
    sed -e '/m64=/s/lib64/lib/' -i.orig gcc/config/i386/t-linux64
}

# --- Chapter 5: the cross toolchain ------------------------------------------

binutils_pass1() {
    mkdir build && cd build
    ../configure --prefix="$LFS/tools" --with-sysroot="$LFS" --target="$LFS_TGT" \
        --disable-nls --enable-gprofng=no --disable-werror \
        --enable-new-dtags --enable-default-hash-style=gnu
    make
    make install
}

gcc_pass1() {
    gcc_prereqs
    mkdir build && cd build
    ../configure --target="$LFS_TGT" --prefix="$LFS/tools" \
        --with-glibc-version=2.44 --with-sysroot="$LFS" --with-newlib \
        --without-headers --enable-default-pie --enable-default-ssp \
        --disable-fixincludes --disable-nls --disable-shared --disable-multilib \
        --disable-threads --disable-libatomic --disable-libgomp \
        --disable-libquadmath --disable-libssp --disable-libvtv \
        --disable-libstdcxx --enable-languages=c,c++
    make
    make install
    cd ..
    cat gcc/limitx.h gcc/glimits.h gcc/limity.h > \
        "$("$LFS_TGT-gcc" -print-file-name=include)/limits.h"
}

linux_headers() {
    make mrproper
    make headers
    find usr/include -type f ! -name '*.h' -delete
    cp -r usr/include "$LFS/usr"
}

glibc() {
    ln -sf ../lib/ld-linux-x86-64.so.2 "$LFS/lib64"
    ln -sf ../lib/ld-linux-x86-64.so.2 "$LFS/lib64/ld-lsb-x86-64.so.3"
    patch -Np1 -i "$src/glibc-fhs-1.patch"
    patch -Np1 -i "$src/glibc-2.44-upstream_fixes-4.patch"
    mkdir build && cd build
    echo "rootsbindir=/usr/sbin" > configparms
    ../configure --prefix=/usr --host="$LFS_TGT" --build="$(../scripts/config.guess)" \
        --disable-nscd libc_cv_slibdir=/usr/lib --enable-kernel=5.10
    make
    sed '/RTLDLIST=/s@/usr@@g' -i elf/ldd
    make DESTDIR="$LFS" install
    # The book's sanity check: the new toolchain must link against the new libc.
    echo 'int main(){}' | "$LFS_TGT-gcc" -x c - -v -Wl,--verbose > dummy.log 2>&1
    "$LFS_TGT-readelf" -l a.out | grep -q ': /lib64/ld-linux-x86-64.so.2'
    grep -q "$LFS/usr/lib/libc.so.6 " dummy.log
}

libstdcxx() {
    mkdir build && cd build
    ../libstdc++-v3/configure --host="$LFS_TGT" --build="$(../config.guess)" \
        CXX="$LFS_TGT-gcc" \
        --prefix=/usr --disable-multilib --disable-nls --disable-libstdcxx-pch \
        --with-gxx-include-dir="/tools/$LFS_TGT/include/c++/16.2.0"
    make
    make DESTDIR="$LFS" install
    rm -f "$LFS"/usr/lib/lib{stdc++{,exp,fs},supc++}.la
}

# --- Chapter 6: temporary tools ----------------------------------------------

autotools() { # autotools <extra configure args...>
    ./configure --prefix=/usr --host="$LFS_TGT" "$@"
    make
    make DESTDIR="$LFS" install
}

m4() { autotools --build="$(build-aux/config.guess)"; }

ncurses() {
    mkdir build
    (cd build && ../configure --prefix="$LFS/tools" AWK=gawk && make -C include && make -C progs tic &&
        install progs/tic "$LFS/tools/bin")
    ./configure --prefix=/usr --host="$LFS_TGT" --build="$(./config.guess)" \
        --mandir=/usr/share/man --with-manpage-format=normal --with-shared \
        --without-normal --with-cxx-shared --without-debug --without-ada \
        --disable-stripping AWK=gawk
    make
    make DESTDIR="$LFS" install
    ln -sf libncursesw.so "$LFS/usr/lib/libncurses.so"
    sed -e 's/^#if.*XOPEN.*$/#if 1/' -i "$LFS/usr/include/curses.h"
}

bash_() {
    # A cross-compiled bash cannot test the C library's getcwd and falls back to
    # its own, which fails across the bind mounts of the build sandbox whenever
    # $PWD is stale ("shell-init: error retrieving current directory"). glibc's
    # getcwd is fine, so say so.
    autotools --build="$(sh support/config.guess)" --without-bash-malloc --docdir=/usr/share/doc/bash-5.3 \
        bash_cv_getcwd_malloc=yes
    ln -sf bash "$LFS/bin/sh"
}

coreutils() {
    autotools --build="$(build-aux/config.guess)" --enable-install-program=hostname
    mv "$LFS/usr/bin/chroot" "$LFS/usr/sbin"
}

diffutils() { autotools gl_cv_func_strcasecmp_works=yes --build="$(./build-aux/config.guess)"; }

file_() {
    mkdir build
    (cd build && ../configure --disable-bzlib --disable-libseccomp --disable-xzlib --disable-zlib && make)
    ./configure --prefix=/usr --host="$LFS_TGT" --build="$(./config.guess)"
    make FILE_COMPILE="$(pwd)/build/src/file"
    make DESTDIR="$LFS" install
    rm -f "$LFS/usr/lib/libmagic.la"
}

findutils() { autotools --localstatedir=/var/lib/locate --build="$(build-aux/config.guess)"; }

gawk() {
    sed -i 's/extras//' Makefile.in
    autotools --build="$(build-aux/config.guess)"
}

grep_() { autotools --build="$(./build-aux/config.guess)"; }
gzip_() { autotools; }
make_() { autotools --build="$(build-aux/config.guess)"; }
patch_() { autotools --build="$(build-aux/config.guess)"; }
sed_() { autotools --build="$(./build-aux/config.guess)"; }
tar_() { autotools --build="$(build-aux/config.guess)"; }

xz() {
    autotools --build="$(build-aux/config.guess)" --disable-static --docdir=/usr/share/doc/xz-5.8.4
    rm -f "$LFS/usr/lib/liblzma.la"
}

binutils_pass2() {
    sed '6031s/$add_dir//' -i ltmain.sh
    mkdir build && cd build
    ../configure --prefix=/usr --build="$(../config.guess)" --host="$LFS_TGT" \
        --disable-nls --enable-shared --enable-gprofng=no --disable-werror \
        --enable-64-bit-bfd --enable-new-dtags --enable-default-hash-style=gnu
    make
    make DESTDIR="$LFS" install
    rm -f "$LFS"/usr/lib/lib{bfd,ctf,ctf-nobfd,opcodes,sframe}.{a,la}
}

gcc_pass2() {
    gcc_prereqs
    mkdir build && cd build
    ../configure --build="$(../config.guess)" --host="$LFS_TGT" --target="$LFS_TGT" \
        --prefix=/usr --with-build-sysroot="$LFS" \
        --enable-default-pie --enable-default-ssp --disable-fixincludes \
        --disable-nls --disable-multilib --disable-libatomic --disable-libgomp \
        --disable-libquadmath --disable-libsanitizer --disable-libssp \
        --disable-libvtv --enable-languages=c,c++ \
        CXX_FOR_TARGET="$LFS_TGT-gcc -nostdinc++" \
        LDFLAGS_FOR_TARGET="-L$PWD/$LFS_TGT/libgcc" \
        target_configargs=gcc_cv_target_thread_file=posix
    make
    make DESTDIR="$LFS" install
    ln -sf gcc "$LFS/usr/bin/cc"
}

step binutils-pass1 binutils-2.47.tar.xz binutils_pass1
step gcc-pass1 gcc-16.2.0.tar.xz gcc_pass1
step linux-headers linux-7.3.1.tar.xz linux_headers
step glibc glibc-2.44.tar.xz glibc
step libstdcxx gcc-16.2.0.tar.xz libstdcxx
step m4 m4-1.4.21.tar.xz m4
step ncurses ncurses-6.6.tar.gz ncurses
step bash bash-5.3.tar.gz bash_
step coreutils coreutils-9.12.tar.xz coreutils
step diffutils diffutils-3.12.tar.xz diffutils
step file file-5.48.tar.gz file_
step findutils findutils-4.11.0.tar.xz findutils
step gawk gawk-5.4.1.tar.xz gawk
step grep grep-3.12.tar.xz grep_
step gzip gzip-1.15.tar.xz gzip_
step make make-4.4.1.tar.gz make_
step patch patch-2.8.1.tar.xz patch_
step sed sed-4.10.tar.xz sed_
step tar tar-1.35.tar.xz tar_
step xz xz-5.8.4.tar.xz xz
step binutils-pass2 binutils-2.47.tar.xz binutils_pass2
step gcc-pass2 gcc-16.2.0.tar.xz gcc_pass2

echo "stage 1 complete: $LFS"
