#!/bin/sh
# --- SDE-COPYRIGHT-NOTE-BEGIN ---
# This copyright note is auto-generated by ./scripts/Create-CopyPatch.
#
# Filename: target/early/initramfs/init.sh
# Copyright (C) 2007 - 2008 The OpenSDE Project
#
# More information can be found in the files COPYING and README.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License. A copy of the
# GNU General Public License can be found in the file COPYING.
# --- SDE-COPYRIGHT-NOTE-END ---

export PATH=/usr/bin:/usr/sbin:/bin:/sbin

modules=
root=
mode=
init=/sbin/init

NOCOLOR=
initargs="$*"

want_mdadm=
want_lvm=

# read kernel arguments
[ -e /proc/cmdline ] || mount -n -t proc  none /proc
set -- $( cat /proc/cmdline )
for x; do
	v="${x#*=}"
	case "$x" in
		root=*)		root="$v"	;;
		init=*)		init="$v"	;;
		rw|ro)		mode="$x"	;;
		modules=*)	modules=$( echo "$v" | tr ',' ' ' )	;;
		nocolor)	export NOCOLOR=yes	;;
		initrdopt=*)	for y in $( echo "$v" | tr ',' ' ' ); do
				case "$y" in
					mdadm)		want_mdadm=yes ;;
					mdadm=*)	want_mdadm="${y#mdadm=}" ;;
					lvm)		want_lvm=yes ;;
					lvm=*)		want_lvm="${y#lvm=}" ;;
				esac
				done
				;;
	esac
done

. /etc/rc.d/functions.in

banner "Starting Early User Space environment"

title "Mounting /proc and /sys"
check mount -n -t usbfs none /proc/bus/usb
check mount -n -t sysfs none /sys
status

[ -x /bin/dmesg ] && /bin/dmesg -n 3

title "Preparing /dev"
check mount -n -t tmpfs none /dev
check cp -a /lib/udev/devices/* /dev
status

title "Starting udev daemon"
echo "" > /sys/kernel/uevent_helper
check udevd --daemon
status

if [ -x /sbin/modprobe -a -n "$modules" ]; then
	title "Preloading requested kernel modules"
	for x in $modules; do
		echo -n " $x"
		check modprobe -q $x
	done
	status
fi

title "Triggering coldplug"
check udevtrigger
check udevsettle
status

sleep 2

[ -n "$root" ] || echo "No root device defined."

if [ ! -e "$root" ]; then
	if [ "$want_mdadm" = yes ]; then
		title "Detecting possible RAID devices"
		check mdadm -E --scan > /etc/mdadm.conf
		status
	fi

	if [ "$want_mdadm" != no -a -s /etc/mdadm.conf ]; then
		# try activating software raids
		title "Activating RAID devices"
		check modprobe md-mod
		check udevsettle
		check mdadm -As --auto=yes
		status
	fi
fi

if [ ! -e "$root" ]; then
	if [ "$want_lvm" = yes ]; then
		title "Detecting possible LVM devices"
		check lvm vgscan
		status
	fi

	if [ "$want_lvm" != no -a -d /etc/lvm/archive ]; then
		title "Activating LVM devices"
		check modprobe dm_mod
		check udevsettle
		check lvm vgchange -ay
		status
	fi
fi

if [ -n "$root" ]; then
	udevsettle

	# give it a second chance to appear (delay 2s)
	[ -e "$root" ] || sleep 2;

	if [ -e "$root" ]; then
		/lib/udev/vol_id "$root" > /tmp/$$.vol_id
		. /tmp/$$.vol_id
		rm /tmp/$$.vol_id

		title "Mounting $root (${ID_FS_TYPE:-unknown}) "
		check mount ${ID_FS_TYPE:+-t $ID_FS_TYPE} ${mode:+-o $mode} "$root" /rootfs
		status
	else
		echo "root device ($root) not found on time."
	fi
fi

# wait for /sbin/init
while [ ! -x "/rootfs$init" ]; do
	echo "Please mount root device on /rootfs and exit to continue"
	setsid /bin/sh < /dev/console > /dev/console 2> /dev/console
done

title "Cleaning up"
check killall udevd
check mount -t none -o move /dev /rootfs/dev
check mount -t none -o move /sys /rootfs/sys
check mount -t none -o move /proc /rootfs/proc
status
	
exec switch_root /rootfs "$init" "$initargs"
