# Following the book's unifdef page.
prepare() {
    # "constexpr" is a keyword in C23, GCC's default.
    sed -i 's/constexpr/unifdef_&/g' unifdef.c
    sed -i 's/ln -s/ln -sf/' Makefile
}

build() {
    make
}

package() {
    make prefix=/usr DESTDIR="$DESTDIR" install
}
