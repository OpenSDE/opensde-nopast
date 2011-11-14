#!/bin/sh
# --- SDE-COPYRIGHT-NOTE-BEGIN ---
# This copyright note is auto-generated by ./scripts/Create-CopyPatch.
#
# Filename: src/tools-source/uname_wrapper.in.sh
# Copyright (C) 2007 - 2011 The OpenSDE Project
#
# More information can be found in the files COPYING and README.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License. A copy of the
# GNU General Public License can be found in the file COPYING.
# --- SDE-COPYRIGHT-NOTE-END ---

# command line arguments
opts=asnrvmpio
longopts=all,kernel-name,nodename,kernel-release,kernel-version,machine,processor,hardware-platform,operating-system

# command line settings
os=
machine=
nodename=
processor=
hardware=
kernel_name=
kernel_release=
kernel_version=

# validate arguments
[ $# -gt 0 ] || set -- -s

output=
oldopts="$@"

if [ -z "$UNAME_WRAPPER_LOGFILE" ]; then
cat >> /tmp/uname.log <<EOT
$$ uname $oldopts
broken environment
$( set )
--
EOT
fi

newopts=$( getopt -o $opts -l $longopts -- "$@" )


if [ $? -ne 0 ]; then
	cat >> $UNAME_WRAPPER_LOGFILE <<-EOT
	$$ uname $oldopts -> $newopts
	failed to parse options.
	--
	EOT
	exit 1
fi

set -- $newopts
while [ $# -gt 0 ]; do
	case "$1" in
		-a|--all)
			os=yes
			machine=yes
			nodename=yes
			processor=yes
			hardware=yes
			kernel_name=yes
			kernel_release=yes
			kernel_version=yes
			;;
		-o|--operating-system)	os=yes	;;
		-m|--machine)		machine=yes	;;
		-n|--nodename)		nodename=yes	;;
		-p|--processor)		processor=yes	;;
		-i|--hardware-platform)	hardware=yes	;;
		-s|--kernel-name)	kernel_name=yes ;;
		-r|--kernel-release)	kernel_release=yes	;;
		-v|--kernel-version)	kernel_version=yes	;;
		--)	shift; break ;;
	esac
	shift
done

# kernel name - Linux
[ -z "$kernel_name" ] || output="$output Linux"

# network node hostname - `hostname`
[ -z "$nodename" ] || output="$output $( hostname )"

# kernel release - TODO: try to guess something useful
if [ -n "$kernel_release" ]; then
	ver= ver0=

	# do i have kernel sources?
	if [ -L $root/usr/src/linux ]; then
		ver=$( readlink $root/usr/src/linux | cut -d- -f2- )
	elif [ -r $root/var/adm/packages/linux ]; then
		ver0=$( sed -n -e 's,^Package Name and Version: [^ ]\+ \([^ ]\+\) .*,\1,p' $root/var/adm/packages/linux )
		ver=$( ls -1t $root/boot/vmlinuz_${ver0}* | sed -e 's,.*/vmlinuz_\(.*\),\1,' | tail -n 1 )
	elif [ -r $root/var/adm/packages/linux-header ]; then
		ver0=$( sed -n -e 's,^Package Name and Version: [^ ]\+ \([^ ]\+\) .*,\1,p' $root/var/adm/packages/linux-header )
	fi

	if [ -z "$ver" -a -n "$ver0" ]; then
		ver="$ver0-inside-sandbox"
	elif [ -z "$ver" -a -z "$ver0" ]; then
		ver="2.6.18-wrapper-could-not-guess"
	fi

	output="$output $ver"
fi

# kernel version - #1 SMP Fri Nov 24 23:49:57 CLST 2006
[ -z "$kernel_version" ] || output="$output #1 SMP $(date)"

# machine hardware name	- $arch_machine
[ -z "$machine" ] || output="$output @@ARCH_MACHINE@@"

# processor type - FIXME: unknown
[ -z "$processor" ] || output="$output unknown"

# hardware platform - FIXME: unknown
[ -z "$hardware" ] || output="$output unknown"

# operating system - GNU/Linux
[ -z "$os" ] || output="$output GNU/Linux"

# remove the heading space
output=$( echo $output )

cat >> $UNAME_WRAPPER_LOGFILE <<EOT
$$ uname $oldopts
$output
--
EOT

echo "$output"
