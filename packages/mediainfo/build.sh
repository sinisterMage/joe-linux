# Not in the book: the newest upstream release, built with its GNU build
# files (Project/GNU/CLI) as its ReadMe says. The command-line program only:
# the graphical interfaces need wxWidgets' GUI or Qt Widgets and are a
# separate build (Project/GNU/GUI, Project/QMake).
build() {
    cd Project/GNU/CLI
    sh ./autogen.sh
    ./configure --prefix=/usr
    make
}

package() {
    cd Project/GNU/CLI
    make DESTDIR="$DESTDIR" install
}
