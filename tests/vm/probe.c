/*
 * A probe for the joe security module tests. Each invocation attempts one
 * operation and reports whether the kernel let it happen:
 *
 *   probe jit-anon            map anonymous writable+executable memory
 *   probe jit-mprotect        write code into memory, then make it executable
 *   probe net                 create an internet socket
 *   probe cap                 use CAP_SYS_ADMIN (set the host name to itself)
 *   probe write PATH          create or append to a file
 *   probe pidfd               open a pidfd for this process (pidfs, read-write)
 *   probe exec PATH [TEST]    run another program, optionally with one probe test
 *   probe exec-check PATH     ask the kernel whether exec of PATH is allowed
 *   probe mount DIR           mount a tmpfs on DIR and unmount it
 *   probe mount-new DIR       mount a tmpfs through fsopen/fsmount/move_mount
 *   probe mount-create        create a tmpfs superblock through fsopen/fsconfig
 *   probe mount-namespace-fd FD  attach an inherited context to a new namespace
 *   probe mount-delegate PATH create a context, then exec PATH with its fd
 *   probe umount-only DIR     unmount an existing mount
 *   probe remount DIR         remount an existing mount
 *   probe mount-setattr DIR   set MOUNT_ATTR_NODEV on an existing mount
 *   probe userns              create a user namespace
 *   probe userns-jit          try anonymous executable memory after CLONE_NEWUSER
 *   probe cap-only-userns     drop root uid, retain CAP_SYS_ADMIN, then CLONE_NEWUSER
 *   probe ipc-signal          signal a different process with the same root uid
 *   probe ipc-sysv            attach a child to a root-owned SysV shm segment
 *   probe ipc-sysv-ctl        remove a root-owned SysV shm segment
 *   probe ipc-sysv-info       query global SysV shm information (no object)
 *   probe ptrace-root         attach to a different process with the same uid
 *   probe ptrace-write        use PTRACE_TRACEME and write the same code word
 *   probe proc-mem-write      write the same code word through /proc/PID/mem
 *   probe process-vm-write    write the same data word through process_vm_writev
 *   probe block-write PATH    open a block device for writing, without writing
 *
 * Prints "allowed" and exits 0, or prints "denied: <reason>" and exits 1.
 * Built as a static binary so it has no libraries to be sealed.
 */
#define _GNU_SOURCE
#include <errno.h>
#include <fcntl.h>
#include <linux/capability.h>
#include <linux/mount.h>
#include <sched.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/ipc.h>
#include <sys/mman.h>
#include <sys/mount.h>
#include <sys/prctl.h>
#include <sys/ptrace.h>
#include <sys/shm.h>
#include <sys/socket.h>
#include <sys/syscall.h>
#include <sys/uio.h>
#include <sys/wait.h>
#include <unistd.h>

#ifndef AT_EXECVE_CHECK
#define AT_EXECVE_CHECK 0x10000
#endif
#ifndef FSMOUNT_NAMESPACE
#define FSMOUNT_NAMESPACE 0x00000002
#endif

static int verdict(int failed)
{
	if (failed) {
		printf("denied: %s\n", strerror(errno));
		return 1;
	}
	puts("allowed");
	return 0;
}

static int setup_failed(void)
{
	printf("setup failed: %s\n", strerror(errno));
	return 2;
}

static long shared_word;

/* A successfully stopped child whose parent is its tracer, or -1. */
static pid_t traceme_child(void)
{
	pid_t pid = fork();
	int status, saved;

	if (pid == 0) {
		alarm(5);
		if (ptrace(PTRACE_TRACEME, 0, NULL, NULL))
			_exit(100);
		raise(SIGSTOP);
		for (;;)
			pause();
	}
	if (pid < 0)
		return -1;
	if (waitpid(pid, &status, WUNTRACED) < 0) {
		saved = errno;
		kill(pid, SIGKILL);
		waitpid(pid, &status, 0);
		errno = saved;
		return -1;
	}
	if (!WIFSTOPPED(status)) {
		errno = EACCES;
		return -1;
	}
	return pid;
}

/* The child always exits, even when the operation being tested is refused. */
static pid_t pausing_child(void)
{
	pid_t pid = fork();

	if (pid == 0) {
		alarm(2);
		for (;;)
			pause();
	}
	return pid;
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
	if (!strcmp(test, "pidfd")) {
#ifndef SYS_pidfd_open
#define SYS_pidfd_open 434
#endif
		int fd = syscall(SYS_pidfd_open, getpid(), 0);
		return verdict(fd < 0);
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
			if (argc > 3)
				execl(arg, arg, argv[3], (char *)NULL);
			else
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
		if (argc > 3 && (!WIFEXITED(status) || WEXITSTATUS(status) != 0)) {
			errno = EACCES;
			return verdict(1);
		}
		return verdict(0);
	}
	if (!strcmp(test, "exec-check") && arg) {
		extern char **environ;
		char *const av[] = { (char *)arg, NULL };
		int fd = open(arg, O_RDONLY);

		if (fd < 0)
			return verdict(1);
		return verdict(syscall(SYS_execveat, fd, "", av, environ,
				       AT_EMPTY_PATH | AT_EXECVE_CHECK));
	}
	if (!strcmp(test, "mount") && arg) {
		if (mount("probe", arg, "tmpfs", 0, NULL))
			return verdict(1);
		if (umount(arg))
			return verdict(1);
		return verdict(0);
	}
	if (!strcmp(test, "mount-create")) {
		int fd = syscall(SYS_fsopen, "tmpfs", 0);
		int ret, saved;

		if (fd < 0)
			return verdict(1);
		ret = syscall(SYS_fsconfig, fd, FSCONFIG_CMD_CREATE, NULL, NULL, 0);
		saved = errno;
		close(fd);
		errno = saved;
		return verdict(ret);
	}
	if (!strcmp(test, "mount-new") && arg) {
		int fsfd, mfd, saved;

		fsfd = syscall(SYS_fsopen, "tmpfs", 0);
		if (fsfd < 0)
			return verdict(1);
		if (syscall(SYS_fsconfig, fsfd, FSCONFIG_CMD_CREATE, NULL, NULL, 0)) {
			saved = errno;
			close(fsfd);
			errno = saved;
			return verdict(1);
		}
		mfd = syscall(SYS_fsmount, fsfd, 0, 0);
		if (mfd < 0) {
			saved = errno;
			close(fsfd);
			errno = saved;
			return verdict(1);
		}
		if (syscall(SYS_move_mount, mfd, "", AT_FDCWD, arg,
			    MOVE_MOUNT_F_EMPTY_PATH)) {
			saved = errno;
			close(mfd);
			close(fsfd);
			errno = saved;
			return verdict(1);
		}
		close(mfd);
		close(fsfd);
		if (umount(arg))
			return verdict(1);
		return verdict(0);
	}
	if (!strcmp(test, "mount-namespace-fd") && arg) {
		int nsfd = syscall(SYS_fsmount, atoi(arg),
				   FSMOUNT_NAMESPACE | FSMOUNT_CLOEXEC, 0);

		if (nsfd < 0)
			return verdict(1);
		close(nsfd);
		return verdict(0);
	}
	if (!strcmp(test, "mount-delegate") && arg) {
		int fsfd = syscall(SYS_fsopen, "tmpfs", 0);
		int status, saved;
		pid_t pid;

		if (fsfd < 0)
			return setup_failed();
		if (syscall(SYS_fsconfig, fsfd, FSCONFIG_CMD_CREATE, NULL, NULL, 0)) {
			saved = errno;
			close(fsfd);
			errno = saved;
			return setup_failed();
		}
		pid = fork();
		if (pid == 0) {
			char fd[32];

			snprintf(fd, sizeof(fd), "%d", fsfd);
			execl(arg, arg, "mount-namespace-fd", fd, (char *)NULL);
			_exit(127);
		}
		if (pid < 0) {
			saved = errno;
			close(fsfd);
			errno = saved;
			return setup_failed();
		}
		waitpid(pid, &status, 0);
		close(fsfd);
		if (!WIFEXITED(status) || WEXITSTATUS(status) != 0)
			errno = EACCES;
		return verdict(!WIFEXITED(status) || WEXITSTATUS(status) != 0);
	}
	if (!strcmp(test, "umount-only") && arg)
		return verdict(umount(arg));
	if (!strcmp(test, "remount") && arg)
		return verdict(mount(NULL, arg, NULL, MS_REMOUNT, NULL));
	if (!strcmp(test, "mount-setattr") && arg) {
		struct mount_attr attr = { .attr_set = MOUNT_ATTR_NODEV };

		return verdict(syscall(SYS_mount_setattr, AT_FDCWD, arg, 0,
				       &attr, sizeof(attr)));
	}
	if (!strcmp(test, "userns"))
		return verdict(unshare(CLONE_NEWUSER));
	if (!strcmp(test, "userns-jit")) {
		void *p;

		if (unshare(CLONE_NEWUSER))
			return verdict(1);
		p = mmap(NULL, 4096, PROT_READ | PROT_WRITE | PROT_EXEC,
			 MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
		return verdict(p == MAP_FAILED);
	}
	if (!strcmp(test, "cap-only-userns")) {
		struct __user_cap_header_struct header = {
			.version = _LINUX_CAPABILITY_VERSION_3,
		};
		struct __user_cap_data_struct data[2] = { { 0 } };

		if (prctl(PR_SET_KEEPCAPS, 1) || setuid(65534))
			return verdict(1);
		data[0].permitted = 1U << CAP_SYS_ADMIN;
		data[0].effective = 1U << CAP_SYS_ADMIN;
		if (syscall(SYS_capset, &header, data))
			return verdict(1);
		return verdict(unshare(CLONE_NEWUSER));
	}
	if (!strcmp(test, "ipc-signal")) {
		pid_t pid = pausing_child();
		int status, ret, saved;

		if (pid < 0)
			return verdict(1);
		ret = kill(pid, SIGUSR1);
		saved = errno;
		waitpid(pid, &status, 0);
		errno = saved;
		return verdict(ret);
	}
	if (!strcmp(test, "ipc-sysv")) {
		int id = shmget(IPC_PRIVATE, 4096, IPC_CREAT | 0600);
		pid_t pid;
		int status;

		if (id < 0)
			return verdict(1);
		pid = fork();
		if (pid == 0) {
			void *p = shmat(id, NULL, 0);

			if (p == (void *)-1)
				_exit(1);
			shmdt(p);
			_exit(0);
		}
		if (pid < 0) {
			shmctl(id, IPC_RMID, NULL);
			return verdict(1);
		}
		waitpid(pid, &status, 0);
		shmctl(id, IPC_RMID, NULL);
		if (!WIFEXITED(status) || WEXITSTATUS(status) != 0)
			errno = EACCES;
		return verdict(!WIFEXITED(status) || WEXITSTATUS(status) != 0);
	}
	if (!strcmp(test, "ipc-sysv-ctl")) {
		int id = shmget(IPC_PRIVATE, 4096, IPC_CREAT | 0600);

		if (id < 0)
			return setup_failed();
		return verdict(shmctl(id, IPC_RMID, NULL));
	}
	if (!strcmp(test, "ipc-sysv-info")) {
		struct shminfo info;

		return verdict(shmctl(0, IPC_INFO, (void *)&info) < 0);
	}
	if (!strcmp(test, "ptrace-root")) {
		pid_t pid = pausing_child();
		int status, ret, saved;

		if (pid < 0)
			return verdict(1);
		ret = ptrace(PTRACE_ATTACH, pid, NULL, NULL);
		saved = errno;
		if (!ret && waitpid(pid, &status, WUNTRACED) < 0) {
			ret = -1;
			saved = errno;
		}
		if (!ret && ptrace(PTRACE_DETACH, pid, NULL, NULL)) {
			ret = -1;
			saved = errno;
		}
		kill(pid, SIGKILL);
		waitpid(pid, &status, 0);
		errno = saved;
		return verdict(ret);
	}
	if (!strcmp(test, "ptrace-write")) {
		pid_t pid = traceme_child();
		long word;
		int status, ret, saved, attempted = 0, cleanup_failed = 0;

		if (pid < 0)
			return setup_failed();
		errno = 0;
		word = ptrace(PTRACE_PEEKTEXT, pid, (void *)main, NULL);
		ret = errno ? -1 : 0;
		saved = errno;
		if (!ret) {
			attempted = 1;
			ret = ptrace(PTRACE_POKETEXT, pid, (void *)main, (void *)word);
			saved = errno;
		}
		if (ptrace(PTRACE_DETACH, pid, NULL, NULL)) {
			saved = errno;
			cleanup_failed = 1;
		}
		kill(pid, SIGKILL);
		waitpid(pid, &status, 0);
		errno = saved;
		if (!attempted || cleanup_failed)
			return setup_failed();
		return verdict(ret);
	}
	if (!strcmp(test, "proc-mem-write")) {
		pid_t pid = traceme_child();
		char path[64];
		long word;
		int fd, status, ret = -1, saved, attempted = 0, cleanup_failed = 0;

		if (pid < 0)
			return setup_failed();
		snprintf(path, sizeof(path), "/proc/%d/mem", pid);
		fd = open(path, O_RDWR);
		if (fd < 0) {
			saved = errno;
		} else {
			ret = pread(fd, &word, sizeof(word), (off_t)main) == sizeof(word) ? 0 : -1;
			if (!ret) {
				attempted = 1;
				ret = pwrite(fd, &word, sizeof(word), (off_t)main) == sizeof(word) ? 0 : -1;
			}
			saved = errno;
			close(fd);
		}
		if (ptrace(PTRACE_DETACH, pid, NULL, NULL)) {
			saved = errno;
			cleanup_failed = 1;
		}
		kill(pid, SIGKILL);
		waitpid(pid, &status, 0);
		errno = saved;
		if (!attempted || cleanup_failed)
			return setup_failed();
		return verdict(ret);
	}
	if (!strcmp(test, "process-vm-write")) {
		pid_t pid = pausing_child();
		long word;
		struct iovec local = { .iov_base = &word, .iov_len = sizeof(word) };
		struct iovec remote = { .iov_base = &shared_word, .iov_len = sizeof(word) };
		int status, ret, saved, attempted = 0;

		if (pid < 0)
			return setup_failed();
		ret = syscall(SYS_process_vm_readv, pid, &local, 1, &remote, 1, 0) == sizeof(word) ? 0 : -1;
		if (!ret) {
			attempted = 1;
			ret = syscall(SYS_process_vm_writev, pid, &local, 1, &remote, 1, 0) == sizeof(word) ? 0 : -1;
		}
		saved = errno;
		kill(pid, SIGKILL);
		waitpid(pid, &status, 0);
		errno = saved;
		if (!attempted)
			return setup_failed();
		return verdict(ret);
	}
	if (!strcmp(test, "block-write") && arg) {
		int fd = open(arg, O_WRONLY);

		if (fd < 0)
			return verdict(1);
		close(fd);
		return verdict(0);
	}
	fprintf(stderr, "usage: probe jit-anon|jit-mprotect|net|cap|write PATH|exec PATH [TEST]|exec-check PATH|mount DIR|mount-new DIR|mount-create|mount-namespace-fd FD|mount-delegate PATH|umount-only DIR|remount DIR|mount-setattr DIR|userns|userns-jit|cap-only-userns|ipc-signal|ipc-sysv|ipc-sysv-ctl|ipc-sysv-info|ptrace-root|ptrace-write|proc-mem-write|process-vm-write|block-write PATH\n");
	return 2;
}
