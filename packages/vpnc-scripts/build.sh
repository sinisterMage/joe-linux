# Not in the book: upstream's repository at the commit named in
# package.zon (it makes no releases).
#
# The script is installed as /usr/share/vpnc-scripts/vpnc-script, as in
# Debian, not /etc/vpnc/vpnc-script as in Fedora and Arch Linux: files in
# /etc are configuration and never sealed, and the script is run by root
# (openconnect, vpnc), whose shell runs only sealed scripts once the
# security module enforces. Hooks an administrator adds still go in
# /etc/vpnc/<phase>.d (pre-init, connect, post-connect, disconnect,
# post-disconnect), which the script reads.
package() {
    # Only the script itself: the variants (vpnc-script-sshd,
    # vpnc-script-ptrtd) are specialised examples.
    install -Dm755 vpnc-script "$DESTDIR/usr/share/vpnc-scripts/vpnc-script"
}
