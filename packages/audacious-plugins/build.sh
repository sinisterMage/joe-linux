# Following the book's Audacious page (its audacious-plugins part), GTK 3
# only like audacious itself (see there). Every plugin is named so that the
# build root cannot change the result: most of them are built whenever
# their library happens to be found.
#
# On beyond the book: Opus (opusfile) and WavPack, which the book turns off
# because it has no pages for them; joe Linux has both.
#
# Off, because the library has no recipe: AAC (FAAD2), AdPlug, CD audio
# (libcdio, libcddb), cue sheets (libcue), ModPlug, OpenMPT, SID
# (libsidplayfp), MMS (libmms), HTTP through neon (GIO's transport handles
# http:// and the rest), the bs2b crossfeed, JACK, SDL output, sndio, LIRC,
# and the Qt-only plugins (Ampache, the stream tuner, Qt audio output). OSS
# is obsolete; Core Audio and Now Playing are macOS only.
build() {
    mkdir build
    cd build
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        -D gtk=true \
        -D gtk2=false \
        -D qt=false \
        -D qt5=false \
        -D gtkui=true \
        -D qtui=false \
        -D skins=true \
        -D asx=true \
        -D asx3=true \
        -D cue=false \
        -D m3u=true \
        -D pls=true \
        -D xspf=true \
        -D gio=true \
        -D mms=false \
        -D neon=false \
        -D aac=false \
        -D adplug=false \
        -D amidiplug=true \
        -D cdaudio=false \
        -D cdaudio-cddb=false \
        -D console=true \
        -D ffaudio=true \
        -D flac=true \
        -D metronome=true \
        -D modplug=false \
        -D mpg123=true \
        -D openmpt=false \
        -D opus=true \
        -D psf=true \
        -D sid=false \
        -D sndfile=true \
        -D tonegen=true \
        -D vorbis=true \
        -D vtx=true \
        -D wavpack=true \
        -D xsf=true \
        -D alsa=true \
        -D coreaudio=false \
        -D filewriter=true \
        -D filewriter-flac=true \
        -D filewriter-mp3=true \
        -D filewriter-ogg=true \
        -D jack=false \
        -D oss=false \
        -D pipewire=true \
        -D pulse=true \
        -D qtaudio=false \
        -D sdlout=false \
        -D sndio=false \
        -D albumart=true \
        -D ampache=false \
        -D aosd=true \
        -D delete-files=true \
        -D filebrowser=true \
        -D hotkey=true \
        -D lirc=false \
        -D lyrics=true \
        -D mac-now-playing=false \
        -D mpris2=true \
        -D notify=true \
        -D playback-history=true \
        -D playlist-manager=true \
        -D scrobbler2=true \
        -D searchtool=true \
        -D songchange=true \
        -D songinfo=true \
        -D statusicon=true \
        -D streamtuner=false \
        -D background-music=true \
        -D bitcrusher=true \
        -D bs2b=false \
        -D compressor=true \
        -D crossfade=true \
        -D crystalizer=true \
        -D echo=true \
        -D ladspa=true \
        -D mixer=true \
        -D resample=true \
        -D silence-removal=true \
        -D soxr=true \
        -D speedpitch=true \
        -D stereo=true \
        -D voice-removal=true \
        -D blurscope=true \
        -D gl-spectrum=true \
        -D spectrum-analyzer=true \
        -D vumeter=true
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
