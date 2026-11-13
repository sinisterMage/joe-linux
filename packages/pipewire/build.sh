build() {
    mkdir build
    cd build
    # The session manager is wireplumber, a package of its own.
    #
    # Built: ALSA devices and the ALSA plugin, V4L2 devices (kernel
    # interface), the GStreamer elements and device provider, the
    # PulseAudio-compatible server (needs no PulseAudio), pw-cat with
    # libsndfile, RAOP (OpenSSL), Opus for RTP, systemd user units.
    #
    # Not built: Bluetooth (bluez, and with it libusb), JACK and the JACK
    # replacement libraries, libcamera, the v4l2 LD_PRELOAD shim, libpulse
    # tunnels, Avahi, FFmpeg, Vulkan, SDL2, ROC, LV2, libmysofa, WebRTC
    # echo cancelling, the X11 bell (libcanberra), FFADO, snap, ebur128,
    # FFTW, ONNX, AVB and ALSA compress offload. The PulseAudio GSettings
    # schema belongs to pulseaudio.
    #
    # libdrm and ncurses (pw-top) have no switch; both are dependencies.
    meson setup .. \
        --prefix=/usr \
        --buildtype=release \
        -D session-managers="[]" \
        -D udevrulesdir=/usr/lib/udev/rules.d \
        -D alsa=enabled \
        -D pipewire-alsa=enabled \
        -D v4l2=enabled \
        -D udev=enabled \
        -D dbus=enabled \
        -D libsystemd=enabled \
        -D logind=enabled \
        -D logind-provider=libsystemd \
        -D systemd-user-service=enabled \
        -D systemd-system-service=disabled \
        -D gstreamer=enabled \
        -D gstreamer-device-provider=enabled \
        -D sndfile=enabled \
        -D pw-cat=enabled \
        -D opus=enabled \
        -D raop=enabled \
        -D readline=enabled \
        -D flatpak=enabled \
        -D gsettings=enabled \
        -D gsettings-pulse-schema=disabled \
        -D bluez5=disabled \
        -D libusb=disabled \
        -D jack=disabled \
        -D pipewire-jack=disabled \
        -D pipewire-v4l2=disabled \
        -D libcamera=disabled \
        -D libpulse=disabled \
        -D avahi=disabled \
        -D ffmpeg=disabled \
        -D pw-cat-ffmpeg=disabled \
        -D vulkan=disabled \
        -D sdl2=disabled \
        -D roc=disabled \
        -D lv2=disabled \
        -D libmysofa=disabled \
        -D echo-cancel-webrtc=disabled \
        -D x11=disabled \
        -D x11-xfixes=disabled \
        -D libcanberra=disabled \
        -D libffado=disabled \
        -D snap=disabled \
        -D selinux=disabled \
        -D ebur128=disabled \
        -D fftw=disabled \
        -D onnxruntime=disabled \
        -D avb=disabled \
        -D compress-offload=disabled \
        -D evl=disabled \
        -D docs=disabled \
        -D man=disabled \
        -D examples=disabled \
        -D tests=disabled \
        -D installed_tests=disabled
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install

    # alsa-lib reads /etc/alsa/conf.d, not the directory the ALSA plugin's
    # configuration is installed in. With these links the ALSA default
    # device is PipeWire, so programs that only speak ALSA (GStreamer's
    # alsasink among them) share the sound card with everything else.
    install -d "$DESTDIR/etc/alsa/conf.d"
    ln -s /usr/share/alsa/alsa.conf.d/50-pipewire.conf \
        /usr/share/alsa/alsa.conf.d/99-pipewire-default.conf \
        -t "$DESTDIR/etc/alsa/conf.d"
}
