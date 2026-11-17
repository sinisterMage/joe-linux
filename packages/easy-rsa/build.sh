# Not in the book: the newest upstream release, installed as its README
# describes: there is nothing to build. easyrsa looks for its support files
# (openssl-easyrsa.cnf and the x509-types directory) in the CA's own
# directory first and then in system places, /usr/share/easy-rsa among
# them, where upstream's copies go. Each CA lives in a directory of its
# own (easyrsa init-pki makes ./pki and copies the support files into it),
# with its settings in a vars file, of which vars.example is upstream's
# template.
package() {
    install -Dm755 easyrsa "$DESTDIR/usr/bin/easyrsa"
    install -Dm644 openssl-easyrsa.cnf "$DESTDIR/usr/share/easy-rsa/openssl-easyrsa.cnf"
    install -Dm644 vars.example "$DESTDIR/usr/share/easy-rsa/vars.example"
    install -d "$DESTDIR/usr/share/easy-rsa/x509-types"
    install -m644 x509-types/* "$DESTDIR/usr/share/easy-rsa/x509-types/"
}
