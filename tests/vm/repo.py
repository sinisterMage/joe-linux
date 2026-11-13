"""A package repository on the host, built with dave and served to the guest."""

import os
import shutil
import subprocess

TOP = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
DAVE = os.path.join(TOP, "dave", "zig-out", "bin", "dave")
CODE_KEY = os.path.join(TOP, "build", "keys", "joe-code.key")
PORT = 8642
# QEMU's user-mode network presents the host as 10.0.2.2.
GUEST_HOST = "10.0.2.2"
GUEST_URL = f"http://{GUEST_HOST}:{PORT}"


def serve_directory(path, port):
    """Serves a directory over HTTP on the loopback interface."""
    return subprocess.Popen(
        ["python3", "-m", "http.server", str(port), "--bind", "127.0.0.1", "--directory", path],
        stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
    )


class Repo:
    def __init__(self, name="vm-repo"):
        self.path = os.path.join(TOP, "build", name)
        self.stage = os.path.join(TOP, "build", name + "-stage")
        self.key = os.path.join(TOP, "build", name + "-key")
        for d in (self.path, self.stage):
            shutil.rmtree(d, ignore_errors=True)
            os.makedirs(d)
        for ext in (".key", ".pub"):
            if os.path.exists(self.key + ext):
                os.remove(self.key + ext)
        subprocess.run([DAVE, "key", "generate", self.key], check=True, stdout=subprocess.DEVNULL)
        self.server = None

    @property
    def public_key(self):
        return self.key + ".pub"

    def package(self, name, version, files, depends=(), allow=()):
        """files: {path: content} or {path: (content, mode)}."""
        stage = os.path.join(self.stage, f"{name}-{version}")
        for path, spec in files.items():
            content, mode = spec if isinstance(spec, tuple) else (spec, 0o644)
            full = os.path.join(stage, path)
            os.makedirs(os.path.dirname(full), exist_ok=True)
            with open(full, "w") as f:
                f.write(content)
            os.chmod(full, mode)
        self.pack_tree(name, version, stage, depends, allow)

    def pack_tree(self, name, version, stage, depends=(), allow=()):
        """Packs an existing directory tree."""
        cmd = [DAVE, "pack", "--name", name, "--version", version, "--out", self.path]
        for d in depends:
            cmd += ["--depends", d]
        for op in allow:
            cmd += ["--allow", op]
        # Sealed with the key joe's kernel trusts, when the distribution has been built.
        if os.path.exists(CODE_KEY):
            cmd += ["--code-key", CODE_KEY]
        subprocess.run(cmd + [stage], check=True, stdout=subprocess.DEVNULL)

    def index(self):
        subprocess.run([DAVE, "repo", "index", self.path, "--key", self.key + ".key"], check=True, stdout=subprocess.DEVNULL)

    def serve(self):
        self.server = serve_directory(self.path, PORT)

    def stop(self):
        if self.server:
            self.server.terminate()
            self.server.wait()
            self.server = None


def script(text):
    """An executable shell script as a package file."""
    return ("#!/bin/sh\n" + text + "\n", 0o755)
