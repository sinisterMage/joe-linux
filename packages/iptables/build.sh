# Following the book's iptables page, but with the nftables back end built
# (the book passes --disable-nftables) and made the default: iptables,
# ip6tables and their -save/-restore names run xtables-nft-multi, which
# drives the kernel's nf_tables through the iptables syntax. The legacy
# x_tables back end is still installed, as iptables-legacy and so on, but
# works only on a kernel built with NETFILTER_XTABLES_LEGACY, which joe's
# is not. The book's example firewall script and its unit are a site's
# policy, not part of the package, and are left out.
build() {
    # libnfnetlink for nfnl_osf (loads OS fingerprints for the osf match),
    # libnetfilter_conntrack for the connlabel match. The BPF compiler and
    # nfsynproxy (libpcap) are off by default and stay off.
    ./configure --prefix=/usr \
        --enable-libipq \
        --enable-libnfnetlink \
        --enable-connlabel \
        --disable-bpf-compiler \
        --disable-nfsynproxy
    make
}

package() {
    make DESTDIR="$DESTDIR" install

    # make install points the plain names at xtables-legacy-multi; point
    # them at the nftables back end instead, as distributions shipping
    # iptables-nft do.
    local name
    for name in iptables iptables-restore iptables-save \
                ip6tables ip6tables-restore ip6tables-save; do
        ln -sfn xtables-nft-multi "$DESTDIR/usr/sbin/$name"
    done
}
