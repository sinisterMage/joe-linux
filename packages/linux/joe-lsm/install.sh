#!/bin/bash
# Adds the joe security module to an unpacked kernel tree (the current
# directory). Run from the kernel recipe's prepare step.
#
#   install.sh DIRECTORY_WITH_THIS_FILE
set -euo pipefail
src=$1

[[ -e $src/joe_keys.h ]] || {
    echo "joe-lsm: joe_keys.h is missing; it is generated from the code-signing key by bootstrap/build-packages.sh" >&2
    exit 1
}
mkdir security/joe
cp "$src/joe.c" "$src/joe_keys.h" "$src/Kconfig" "$src/Makefile" security/joe/

# Each edit must find its anchor: a kernel update that moves one should fail
# here rather than produce a kernel without the module.
edit() { # edit FILE ANCHOR_REGEX SED_COMMAND
    grep -q "$2" "$1" || { echo "joe-lsm: anchor not found in $1: $2" >&2; exit 1; }
    sed -i "$3" "$1"
}
edit security/Kconfig '^source "security/ipe/Kconfig"' \
    's|^source "security/ipe/Kconfig"|&\nsource "security/joe/Kconfig"|'
edit security/Makefile '^obj-$(CONFIG_SECURITY_IPE)' \
    's|^obj-$(CONFIG_SECURITY_IPE).*|&\nobj-$(CONFIG_SECURITY_JOE)\t\t+= joe/|'
edit include/uapi/linux/lsm.h '^#define LSM_ID_IPE' \
    's|^#define LSM_ID_IPE.*|&\n#define LSM_ID_JOE\t\t114|'
edit include/linux/lsm_count.h '^#if IS_ENABLED(CONFIG_SECURITY_IPE)' \
    's|^#if IS_ENABLED(CONFIG_SECURITY_IPE)|#if IS_ENABLED(CONFIG_SECURITY_JOE)\n#define JOE_ENABLED 1,\n#else\n#define JOE_ENABLED\n#endif\n\n&|'
edit include/linux/lsm_count.h 'IPE_ENABLED)' \
    's|\t\tIPE_ENABLED)|\t\tIPE_ENABLED\t\t\\\n\t\tJOE_ENABLED)|'
grep -q 'JOE_ENABLED)' include/linux/lsm_count.h || { echo "joe-lsm: could not register in lsm_count.h" >&2; exit 1; }
