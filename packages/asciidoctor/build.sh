# Following the book's Asciidoctor page: the gem is built from the source
# release with gem build. Instead of the book's plain gem install (into
# Ruby's own gem directory), it is installed into Ruby's vendor gem
# directory, /usr/lib/ruby/vendor_ruby/gems/4.0.0, which RubyGems searches
# when it exists, leaving the default one to the gems that come with Ruby.

# Keep RubyGems away from root's home in the shared build root.
_gem_env() {
    export HOME="$PWD/.home" XDG_CACHE_HOME="$PWD/.home/cache" XDG_DATA_HOME="$PWD/.home/data"
}

build() {
    _gem_env
    gem build asciidoctor.gemspec
}

package() {
    _gem_env
    local vendor
    vendor=$(ruby -e 'print Gem.vendor_dir')
    # The executable stub /usr/bin/asciidoctor loads the gem from there.
    gem install --local --no-document --ignore-dependencies \
        --install-dir "$DESTDIR$vendor" \
        --bindir "$DESTDIR/usr/bin" \
        asciidoctor-2.0.26.gem
    # A second copy of the gem file, kept only for reinstalling it.
    rm -v "$DESTDIR$vendor/cache/asciidoctor-2.0.26.gem"

    install -vDm644 man/asciidoctor.1 "$DESTDIR/usr/share/man/man1/asciidoctor.1"
}
