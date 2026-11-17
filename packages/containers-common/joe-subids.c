// SPDX-License-Identifier: MIT
// Initialize Shadow's automatic allocation and migrate existing local users.
// libsubid owns locking and free-range selection; retain all existing ranges.
#define _GNU_SOURCE
#include <errno.h>
#include <fcntl.h>
#include <pwd.h>
#include <stdbool.h>
#include <stdio.h>
#include <string.h>
#include <sys/stat.h>
#include <unistd.h>
#include <shadow/subid.h>

struct policy {
    unsigned long uid_min, uid_max, uid_count, gid_count;
};

static bool read_policy(struct policy *policy)
{
    FILE *file = fopen("/etc/login.defs", "re");
    if (!file) {
        perror("/etc/login.defs");
        return false;
    }
    char line[4096], key[64];
    unsigned long value;
    while (fgets(line, sizeof(line), file)) {
        if (sscanf(line, "%63s %lu", key, &value) != 2)
            continue;
        if (!strcmp(key, "UID_MIN")) policy->uid_min = value;
        else if (!strcmp(key, "UID_MAX")) policy->uid_max = value;
        else if (!strcmp(key, "SUB_UID_COUNT")) policy->uid_count = value;
        else if (!strcmp(key, "SUB_GID_COUNT")) policy->gid_count = value;
    }
    bool ok = !ferror(file);
    if (!ok) perror("reading /etc/login.defs");
    if (fclose(file)) {
        perror("closing /etc/login.defs");
        ok = false;
    }
    return ok;
}

static bool initialize(const char *path)
{
    int fd = open(path, O_WRONLY | O_CREAT | O_EXCL | O_CLOEXEC, 0644);
    if (fd < 0) {
        if (errno == EEXIST) return true;
        perror(path);
        return false;
    }
    if (close(fd)) {
        perror(path);
        return false;
    }
    return true;
}

static bool ensure_range(const char *owner, unsigned long count, bool group)
{
    // A zero count explicitly disables automatic allocation in login.defs.
    if (!count) return true;
    struct subid_range *ranges = NULL;
    int found = group ? subid_get_gid_ranges(owner, &ranges)
                      : subid_get_uid_ranges(owner, &ranges);
    if (ranges) subid_free(ranges);
    if (found > 0) return true;
    if (!found) {
        struct subordinate_range range = { .owner = owner, .count = count };
        if (group ? subid_grant_gid_range(&range, true)
                  : subid_grant_uid_range(&range, true))
            return true;
    }
    fprintf(stderr, "Cannot allocate subordinate %s range for %s\n",
            group ? "GID" : "UID", owner);
    return false;
}

int main(void)
{
    struct policy policy = { 1000, 60000, 65536, 65536 };
    if (!read_policy(&policy)) return 1;
    umask(022);
    if (!initialize("/etc/subuid") || !initialize("/etc/subgid")) return 1;
    if (!subid_init("joe-setup-subids", stderr)) return 1;
    FILE *file = fopen("/etc/passwd", "re");
    if (!file) {
        perror("/etc/passwd");
        return 1;
    }
    // Own the reentrant record buffer: libsubid may itself call NSS functions.
    char buffer[16384];
    struct passwd account, *entry;
    bool ok = true;
    for (;;) {
        int error = fgetpwent_r(file, &account, buffer, sizeof(buffer), &entry);
        if (error) {
            if (error != ENOENT) {
                errno = error;
                perror("reading /etc/passwd");
                ok = false;
            }
            break;
        }
        if (!entry) break;
        if (!entry->pw_uid || entry->pw_uid < policy.uid_min ||
            entry->pw_uid > policy.uid_max)
            continue;
        if (!ensure_range(entry->pw_name, policy.uid_count, false) ||
            !ensure_range(entry->pw_name, policy.gid_count, true)) {
            ok = false;
            break;
        }
    }
    if (ferror(file)) {
        perror("reading /etc/passwd");
        ok = false;
    }
    if (fclose(file)) {
        perror("closing /etc/passwd");
        ok = false;
    }
    return ok ? 0 : 1;
}
