# Not in the book: the newest upstream release, built as its Linux build
# instructions say (configure, then make -C build), with the options Arch
# Linux and HandBrake's Flatpak use.
#
# HandBrake always builds its own static FFmpeg (with HandBrake's patches,
# which it requires), x265 (8, 10 and 12 bit in one library), SVT-AV1,
# dav1d, zimg, libdvdread, libdvdnav and libbluray; configure has no option
# to use the system's copies, and Arch and Flathub ship the same bundle.
# Everything else (libass, x264, Theora, Vorbis, Opus, Speex, LAME, libvpx,
# jansson, TurboJPEG) is the system's, as on every Linux build.

prepare() {
    # The bundled libraries' tarballs, where make looks for them before it
    # would download anything (download/, under the name in each
    # contrib/NAME/module.defs). make checks them against its own SHA-256.
    mkdir download
    local f
    for f in ffmpeg-8.0.2.tar.bz2 \
        x265-snapshot-20260216-13309.tar.gz \
        SVT-AV1-v4.1.0.tar.gz \
        dav1d-1.5.3.tar.bz2 \
        zimg-snapshot-20250624.tar.gz \
        libdvdread-7.0.1.tar.bz2 \
        libdvdnav-7.0.0.tar.bz2 \
        libbluray-1.4.0.tar.xz; do
        cp "$SOURCES/handbrake-contrib-$f" "download/$f"
    done

    # custom.defs is HandBrake's hook for local additions to its make
    # definitions; it is read after the modules' own.
    # - FFmpeg would otherwise detect libdrm, Vulkan, Xlib, XCB, SDL2 and
    #   ALSA in the build root and link them; HandBrake uses none of them
    #   (its FFmpeg has no devices and no hardware decoding here). Only the
    #   compression libraries are kept.
    # - x265 takes its version from x265Version.txt only when told the
    #   source is an archive, as joe's x265 recipe also says; without git
    #   in the build root its cmake script would otherwise run an empty
    #   command.
    cat > custom.defs <<'EOF'
FFMPEG.CONFIGURE.extra += --disable-autodetect --enable-zlib --enable-bzlib --enable-lzma --enable-iconv
X265_8.CONFIGURE.extra += -DGIT_ARCHETYPE=1
X265_10.CONFIGURE.extra += -DGIT_ARCHETYPE=1
X265_12.CONFIGURE.extra += -DGIT_ARCHETYPE=1
EOF
}

build() {
    # --disable-df-fetch: nothing is downloaded; the tarballs are in
    # download/ (prepare).
    #
    # Left out:
    # - Intel Quick Sync (--enable-qsv: oneVPL and Intel's GPU runtime have
    #   no recipes), AMD VCE (AMF: AMD's proprietary runtime) and NVIDIA
    #   NVENC/NVDEC (the proprietary driver's libraries); joe's own ffmpeg
    #   leaves the NVIDIA and AMD interfaces out too.
    # - Dolby Vision metadata (libdovi): its Rust crates would be fetched
    #   during the build.
    # - FDK AAC: non-free; FFmpeg's AAC encoder is used.
    # - NUMA for x265: numactl has no recipe (joe's x265 is built without
    #   it as well).
    ./configure --prefix=/usr \
        --disable-df-fetch \
        --enable-gtk \
        --enable-x265 \
        --disable-numa \
        --disable-fdk-aac \
        --disable-libdovi \
        --disable-qsv \
        --disable-vce \
        --disable-nvenc \
        --disable-nvdec
    # The bundled libraries are installed into build/contrib while building;
    # with the driver's DESTDIR in the environment they would land under
    # $DESTDIR instead.
    env -u DESTDIR make -C build
}

package() {
    # HandBrakeCLI, and ghb with its desktop file, metainfo, icon and
    # translations. The install script's cache updates are skipped when
    # DESTDIR is set.
    make -C build DESTDIR="$DESTDIR" install
}
