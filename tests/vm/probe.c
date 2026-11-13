/*
 * A probe for the joe security module tests. Each invocation attempts one
 * operation and reports whether the kernel let it happen:
 *
 *   probe jit-anon            map anonymous writable+executable memory
 *   probe jit-mprotect        write code into memory, then make it executable
 *   probe net                 create an internet socket
 *   probe cap                 use CAP_SYS_ADMIN (set the host name to itself)
 *   probe write PATH          create or append to a file
 *   probe exec PATH           run another program
 *   probe mount DIR           mount a tmpfs on DIR and unmount it
 *
 * Prints "allowed" and exits 0, or prints "denied: <reason>" and exits 1.
 * Built as a static binary so it has no libraries to be sealed.
 */
#define _GNU_SOURCE
#include <errno.h>
#include <fcntl.h>
#include <stdio.h>
#include <string.h>
#include <sys/mman.h>
#include <sys/mount.h>
#include <sys/socket.h>
#include <sys/wait.h>
#include <unistd.h>

static int verdict(int failed)
{
	if (failed) {
		printf("denied: %s\n", strerror(errno));
		return 1;
	}
	puts("allowed");
	return 0;
}

int main(int argc, char **argv)
{
	const char *test = argc > 1 ? argv[1] : "";
	const char *arg = argc > 2 ? argv[2] : NULL;

	if (!strcmp(test, "jit-anon")) {
		void *p = mmap(NULL, 4096, PROT_READ | PROT_WRITE | PROT_EXEC,
			       MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
		return verdict(p == MAP_FAILED);
	}
	if (!strcmp(test, "jit-mprotect")) {
		unsigned char *p = mmap(NULL, 4096, PROT_READ | PROT_WRITE,
					MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
		if (p == MAP_FAILED)
			return verdict(1);
		p[0] = 0xc3; /* ret */
		if (mprotect(p, 4096, PROT_READ | PROT_EXEC))
			return verdict(1);
		((void (*)(void))p)();
		return verdict(0);
	}
	if (!strcmp(test, "net")) {
		int fd = socket(AF_INET, SOCK_DGRAM, 0);
		return verdict(fd < 0);
	}
	if (!strcmp(test, "cap")) {
		char name[256];
		if (gethostname(name, sizeof(name)))
			return verdict(1);
		return verdict(sethostname(name, strlen(name)));
	}
	if (!strcmp(test, "write") && arg) {
		int fd = open(arg, O_WRONLY | O_CREAT | O_APPEND, 0644);
		if (fd < 0)
			return verdict(1);
		return verdict(write(fd, "x", 1) != 1);
	}
	if (!strcmp(test, "exec") && arg) {
		int status, pipefd[2];
		pid_t pid;
		int err = 0;

		/* The child reports an exec failure through a close-on-exec pipe. */
		if (pipe2(pipefd, O_CLOEXEC))
			return verdict(1);
		pid = fork();
		if (pid == 0) {
			execl(arg, arg, (char *)NULL);
			err = errno;
			write(pipefd[1], &err, sizeof(err));
			_exit(127);
		}
		close(pipefd[1]);
		if (read(pipefd[0], &err, sizeof(err)) == sizeof(err)) {
			waitpid(pid, &status, 0);
			errno = err;
			return verdict(1);
		}
		waitpid(pid, &status, 0);
		return verdict(0);
	}
	if (!strcmp(test, "mount") && arg) {
		if (mount("probe", arg, "tmpfs", 0, NULL))
			return verdict(1);
		umount(arg);
		return verdict(0);
	}
	fprintf(stderr, "usage: probe jit-anon|jit-mprotect|net|cap|write PATH|exec PATH|mount DIR\n");
	return 2;
}
