#!/usr/bin/env bash

if [ ! -d /proc/sys/fs/binfmt_misc ] ; then
	echo 'Loading binfmt kernel module'
	modprobe -q binfmt_misc
fi

if [ ! -d /proc/sys/fs/binfmt_misc ] ; then
	echo "You need support for 'misc binaries' in your kernel!"
	exit 1
fi

if [ ! -f /proc/sys/fs/binfmt_misc/register ] ; then
	echo 'Mounting binfmt'
	mount -t binfmt_misc -o nodev,noexec,nosuid \
		binfmt_misc /proc/sys/fs/binfmt_misc >/dev/null 2>&1
fi

echo ':qemu-arm:M::\x7fELF\x01\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\x28\x00:\xff\xff\xff\xff\xff\xff\xff\x00\xff\xff\xff\xff\xff\xff\xff\xff\xfe\xff\xff\xff:/usr/bin/qemu-arm:OC' >/proc/sys/fs/binfmt_misc/register
echo 'Successfully registered qemu as arm binary userspace emulator'
