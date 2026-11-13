#!/usr/bin/env python3
"""Prints the command blocks of LFS book pages (cached locally).

    cmds.py chapter08/zlib            Linux From Scratch
    cmds.py --blfs general/glib2      Beyond LFS, with downloads and dependencies
"""
import html, os, re, subprocess, sys
LFS = "https://www.linuxfromscratch.org/lfs/view/systemd/"
BLFS = "https://www.linuxfromscratch.org/blfs/view/systemd/"
here = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))), 'build', 'lfs')
os.makedirs(os.path.join(here, 'pages'), exist_ok=True)
args = sys.argv[1:]
blfs = bool(args) and args[0] == "--blfs"
if blfs:
    args = args[1:]
for page in args:
    cache = os.path.join(here, "pages", ("blfs_" if blfs else "") + page.replace("/", "_") + ".html")
    if not os.path.exists(cache):
        subprocess.run(["curl", "-fsSL", "-o", cache, (BLFS if blfs else LFS) + page + ".html"], check=True)
    text = open(cache, encoding="utf-8", errors="replace").read()
    print(f"##### {page}")
    if blfs:
        # Download locations, checksums and dependency lists, as the page states them.
        for m in re.finditer(r'<li class="listitem">\s*<p>(.*?)</p>', text, re.S):
            line = re.sub(r"\s+", " ", html.unescape(re.sub(r"<[^>]+>", "", m.group(1)))).strip()
            if re.match(r"(Download|Required patch|Optional patch|Recommended patch)", line):
                print("# " + line)
        for kind in ("required", "recommended", "optional"):
            for m in re.finditer(r'<p class="%s">(.*?)</p>' % kind, text, re.S):
                line = re.sub(r"\s+", " ", html.unescape(re.sub(r"<[^>]+>", "", m.group(1)))).strip()
                print(f"# {kind}: {line}")
        print("---")
    for m in re.finditer(r'<pre class="(userinput|root)">(.*?)</pre>', text, re.S):
        body = re.sub(r"<[^>]+>", "", m.group(2))
        print(html.unescape(body).strip())
        print("---")
