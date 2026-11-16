# Not in the book: the newest upstream release, built as its INSTALL says.
# The checksum operations (md5, sha1, ...) use gnulib's own code rather than
# OpenSSL's, as coreutils' do.
build() {
    ./configure --prefix=/usr \
        --without-openssl \
        --with-bash-completion-dir=/usr/share/bash-completion/completions
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
