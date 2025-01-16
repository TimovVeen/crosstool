/*
 * Pass arguments to qemu binary
 */

#include <string.h>
#include <unistd.h>

int main(int argc, char **argv, char **envp) {
	char *newargv[argc + 5];

	newargv[0] = argv[0];
	newargv[1] = "-cpu";
	newargv[2] = "cortex-a9";
	newargv[3] = "-L";
	newargv[4] = "/usr/armv7a-softfloat-linux-gnueabi";

	memcpy(&newargv[5], &argv[1], sizeof(*argv) * (argc -1));
	newargv[argc + 4] = NULL;
	return execve("/usr/bin/qemu-arm", newargv, envp);
}
