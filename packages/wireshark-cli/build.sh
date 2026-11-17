# Following the book's Wireshark page (basicnet/wireshark), without the Qt
# GUI (BUILD_wireshark=OFF); sharkd uses the system SpeexDSP resampler.
#
# dumpcap is installed without set-uid and without file capabilities (joe
# cannot set them), so capturing needs root; reading and analysing capture
# files does not. The book's set-gid tshark and its wireshark group are
# left out: without privileges on dumpcap, a group would grant nothing.
build() {
    mkdir build
    cd build
    # The book's options, plus CMAKE_INSTALL_LIBDIR so that nothing can pick
    # lib64, and every optional library stated:
    # - on, packaged: libpcap, libcap, libnl, libssh (sshdump, ciscodump,
    #   wifidump), systemd (sdjournal), GnuTLS, Kerberos, xxHash, zlib,
    #   minizip, Brotli, LZ4, Snappy, zstd, nghttp2/nghttp3, Lua, SBC and Opus;
    # - off, not packaged: MaxMind DB (mmdbresolve), libsmi, zlib-ng,
    #   minizip-ng, SpanDSP, bcg729, AMR-NB and iLBC.
    cmake -D CMAKE_INSTALL_PREFIX=/usr \
        -D CMAKE_INSTALL_LIBDIR=lib \
        -D CMAKE_BUILD_TYPE=Release \
        -D CMAKE_INSTALL_DOCDIR=/usr/share/doc/wireshark-4.6.9 \
        -D BUILD_wireshark=OFF \
        -D BUILD_stratoshark=OFF \
        -D BUILD_sharkd=ON \
        -D BUILD_mmdbresolve=OFF \
        -D BUILD_sdjournal=ON \
        -D BUILD_sshdump=ON \
        -D BUILD_ciscodump=ON \
        -D BUILD_wifidump=ON \
        -D BUILD_dpauxmon=ON \
        -D ENABLE_PCAP=ON \
        -D ENABLE_CAP=ON \
        -D ENABLE_NETLINK=ON \
        -D ENABLE_GNUTLS=ON \
        -D ENABLE_KERBEROS=ON \
        -D ENABLE_XXHASH=ON \
        -D ENABLE_ZLIB=ON \
        -D ENABLE_ZLIBNG=OFF \
        -D ENABLE_MINIZIP=ON \
        -D ENABLE_MINIZIPNG=OFF \
        -D ENABLE_BROTLI=ON \
        -D ENABLE_LZ4=ON \
        -D ENABLE_SNAPPY=ON \
        -D ENABLE_ZSTD=ON \
        -D ENABLE_NGHTTP2=ON \
        -D ENABLE_NGHTTP3=ON \
        -D ENABLE_LUA=ON \
        -D ENABLE_SMI=OFF \
        -D ENABLE_SBC=ON \
        -D ENABLE_OPUS=ON \
        -D ENABLE_SPANDSP=OFF \
        -D ENABLE_BCG729=OFF \
        -D ENABLE_AMRNB=OFF \
        -D ENABLE_ILBC=OFF \
        -D DUMPCAP_INSTALL_OPTION=normal \
        -D ENABLE_DUMPCAP_GROUP=OFF \
        -G Ninja \
        ..
    ninja
    # The manual pages are built by the docs target, not by default, but
    # are installed whenever Asciidoctor is found.
    ninja docs
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
    # Pages for programs that are not built here.
    local page
    for page in wireshark stratoshark strato etwdump falcodump sshdig; do
        rm -f "$DESTDIR/usr/share/man/man1/$page.1"
    done
}
