# Not in the book: perf from tools/perf of the kernel source the linux
# recipe uses, built as tools/perf/Makefile.perf describes. It does not
# depend on the linux package; it works with any kernel.
#
# Every optional feature is stated, since the Makefile uses whatever it
# finds. On: libelf, zlib, lzma, zstd, libunwind (opt-in, for DWARF call
# graphs), libLLVM, Python and Perl scripting and the JVMTI agent for Java.
# The BPF skeletons (off-CPU profiling, BPF counters, lock contention) are
# off: joe's LLVM is built without its BPF back end, so clang cannot compile
# them. EXTRA_CFLAGS=-O2: Perl's compiler flags carry _FORTIFY_SOURCE, which
# fails perf's unoptimised -Werror test for embedding Perl. Off, because joe Linux
# has no recipe for what they need: libtraceevent (tracepoint fields, perf
# trace, sched, kmem, lock), S-Lang (the TUI; perf report uses its stdio
# interface), libdw and libdebuginfod (the elfutils recipe builds only
# libelf), libnuma, libpfm4, capstone, babeltrace2, systemtap's sys/sdt.h,
# libbfd, GTK 2 and CoreSight. Also off: the 32-bit vDSO readers (no
# multilib compiler), the Rust test workloads and shellcheck runs.
_make() {
    make -C tools/perf \
        prefix=/usr \
        lib=lib \
        tipdir=share/perf-core \
        WERROR=0 \
        EXTRA_CFLAGS=-O2 \
        PYTHON=python3 \
        LIBPERL=1 \
        LIBUNWIND=1 \
        BUILD_BPF_SKEL=0 \
        JDIR=/usr/lib/jvm/default \
        NO_LIBTRACEEVENT=1 \
        NO_SLANG=1 \
        NO_LIBDW=1 \
        NO_LIBDEBUGINFOD=1 \
        NO_LIBNUMA=1 \
        NO_LIBPFM4=1 \
        NO_CAPSTONE=1 \
        NO_BABELTRACE2=1 \
        NO_SDT=1 \
        NO_RUST=1 \
        NO_PERF_READ_VDSO32=1 \
        NO_PERF_READ_VDSOX32=1 \
        NO_SHELLCHECK=1 \
        USE_ASCIIDOCTOR=1 \
        "$@"
}

build() {
    _make
    _make man
}

package() {
    _make DESTDIR="$DESTDIR" install-bin install-man

    # The bash completion goes where bash-completion loads it on demand.
    install -d "$DESTDIR/usr/share/bash-completion/completions"
    mv "$DESTDIR/etc/bash_completion.d/perf" "$DESTDIR/usr/share/bash-completion/completions/perf"
    rmdir --ignore-fail-on-non-empty "$DESTDIR/etc/bash_completion.d" "$DESTDIR/etc"

    # The Python module ("import perf"), which upstream installs with the
    # deprecated "setup.py install".
    local site
    site=$(python3 -c 'import sysconfig; print(sysconfig.get_path("platlib"))')
    install -Dm755 tools/perf/python/perf*.so -t "$DESTDIR$site"
}
