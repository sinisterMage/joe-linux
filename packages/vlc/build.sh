build() {
    # The book's configure (BUILDCC=gcc), with every module stated.
    #
    # The interface is Qt 6: with no Qt 5, configure builds the Qt module
    # with qmake6 (modules/gui/qt/qt6.pro: Qt Core, Gui, Widgets and Svg).
    # The book warns that this port is new and partly broken. Where an X
    # display exists (Xwayland in a GNOME session) the interface runs on
    # xcb by itself, which is what the book's QT_QPA_PLATFORM=xcb advice
    # amounts to. skins2 and ncurses are the other interfaces.
    #
    # On, because their libraries have recipes: FFmpeg (avcodec, avformat,
    # swscale), dav1d, libaom, libvpx, x264 and x265, FLAC, Vorbis, Opus,
    # mpg123, Ogg, PNG, JPEG, SVG, FreeType with FriBidi, HarfBuzz and
    # Fontconfig, PulseAudio and ALSA, the SoX resampler, XCB and XVideo,
    # D-Bus, Lua, libarchive, libdvdread, libssh2 (sftp), libvncclient (vnc),
    # Avahi (network shares and Chromecast discovery), udev, libxml2,
    # libgcrypt, GnuTLS, libsecret, libnotify, Chromecast output (protobuf).
    # The teletext decoder is VLC's own (telx), as zvbi has no recipe.
    # Tier-2 adds ASS subtitles, TagLib metadata, Speex, Theora, TwoLAME,
    # FluidSynth MIDI, libsamplerate, Chromaprint, DVD navigation,
    # SRT/RIST transport and MTP devices.
    #
    # Off:
    # - liba52, libmad, FAAD2, libmpeg2 and libdca: no recipes; FFmpeg
    #   decodes AC-3, MP3, AAC, MPEG-2 and DTS. Kate, shine, Musepack,
    #   libmodplug, Game Music Emu and sidplay also have no recipes.
    # - libdvbpsi and libmatroska have no recipes (libebml alone is not
    #   sufficient), so FFmpeg supplies MPEG-TS and Matroska demuxing.
    # - libplacebo: this VLC requires >=0.2.1 and <6; joe ships 7.387.0.
    #   VDPAU has no recipe; libpostproc is gone from FFmpeg.
    # - SDL_image means SDL 1.2's SDL_image.pc, not the available SDL2_image.
    #   OpenCV likewise requires opencv.pc and its old C API, not OpenCV 4.
    # - JACK, libcaca, spatialaudio, libbluray, libcddb, live555, libnfs,
    #   libdsm, libsmb2, libupnp, libmicrodns, goom, projectM, VSXu, LIRC,
    #   aribb24/aribb25, IIDC/DV FireWire, Linear Systems SDI cards and
    #   DeckLink: no recipes.
    # - smbclient: Samba is not part of joe's desktop (gvfs browses SMB).
    # - rdp: written for old FreeRDP releases (pkg-config "freerdp"); FreeRDP
    #   3 installs freerdp3 and a different API.
    # - GStreamer decoding: a fallback that FFmpeg makes unnecessary.
    # - KWallet and KDE Solid actions: there is no KDE. Wayland video output:
    #   incomplete in this release and off by default.
    BUILDCC=gcc ./configure --prefix=/usr \
        --libdir=/usr/lib \
        --disable-static \
        --without-kde-solid \
        --enable-qt \
        --enable-skins2 \
        --enable-ncurses \
        --enable-lua \
        --enable-dbus \
        --enable-archive \
        --enable-dvdread \
        --enable-sftp \
        --enable-vnc \
        --enable-ogg \
        --enable-mpg123 \
        --enable-avcodec \
        --enable-avformat \
        --enable-swscale \
        --enable-aom \
        --enable-dav1d \
        --enable-vpx \
        --enable-flac \
        --enable-vorbis \
        --enable-opus \
        --enable-png \
        --enable-jpeg \
        --enable-x264 \
        --enable-x26410b \
        --enable-x265 \
        --enable-freetype \
        --enable-fribidi \
        --enable-harfbuzz \
        --enable-fontconfig \
        --enable-svg \
        --enable-svgdec \
        --enable-xcb \
        --enable-xvideo \
        --enable-pulse \
        --enable-alsa \
        --enable-soxr \
        --enable-avahi \
        --enable-udev \
        --enable-libxml2 \
        --enable-libgcrypt \
        --enable-gnutls \
        --enable-secret \
        --enable-notify \
        --enable-chromecast \
        --enable-telx \
        --disable-a52 \
        --disable-mad \
        --disable-faad \
        --disable-libmpeg2 \
        --disable-dca \
        --enable-speex \
        --enable-theora \
        --disable-kate \
        --disable-tiger \
        --enable-twolame \
        --disable-shine \
        --disable-mpc \
        --disable-mod \
        --disable-gme \
        --disable-sid \
        --enable-fluidsynth \
        --disable-fluidlite \
        --disable-dvbpsi \
        --disable-matroska \
        --enable-libva \
        --disable-vdpau \
        --disable-libplacebo \
        --disable-postproc \
        --disable-vpl \
        --enable-libass \
        --enable-taglib \
        --enable-samplerate \
        --disable-jack \
        --disable-caca \
        --disable-sdl-image \
        --disable-spatialaudio \
        --enable-chromaprint \
        --enable-dvdnav \
        --disable-bluray \
        --disable-libcddb \
        --disable-live555 \
        --disable-nfs \
        --disable-dsm \
        --disable-smb2 \
        --disable-smbclient \
        --disable-freerdp \
        --enable-srt \
        --enable-librist \
        --disable-shout \
        --enable-mtp \
        --disable-upnp \
        --disable-microdns \
        --disable-goom \
        --disable-projectm \
        --disable-vsxu \
        --disable-lirc \
        --disable-zvbi \
        --disable-aribsub \
        --disable-aribb25 \
        --disable-opencv \
        --disable-dc1394 \
        --disable-dv1394 \
        --disable-linsys \
        --disable-decklink \
        --disable-asdcp \
        --disable-gst-decode \
        --disable-kwallet \
        --disable-wayland
    make
}

package() {
    make DESTDIR="$DESTDIR" docdir=/usr/share/doc/vlc-3.0.24 install

    # make install runs vlc-cache-gen on the staged plugins. The cache
    # records each plugin's size and modification time, which installation
    # does not keep, so it is rebuilt where VLC is installed instead.
    rm -f "$DESTDIR/usr/lib/vlc/plugins/plugins.dat"
    # Optional: VLC works without the cache, it only starts more slowly.
    install -d "$DESTDIR/usr/lib/dave/triggers"
    cat > "$DESTDIR/usr/lib/dave/triggers/45-vlc-plugins.zon" <<'EOT'
.{
    .name = "VLC plugin cache",
    .paths = .{"usr/lib/vlc/plugins/"},
    .exec = .{ "/usr/lib/vlc/vlc-cache-gen", "/usr/lib/vlc/plugins" },
    .optional = true,
}
EOT
}
