# --- SDE-COPYRIGHT-NOTE-BEGIN ---
# This copyright note is auto-generated by ./scripts/Create-CopyPatch.
#
# Filename: target/share/squashfs/build.sh
# Copyright (C) 2011 The OpenSDE Project
#
# More information can be found in the files COPYING and README.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License. A copy of the
# GNU General Public License can be found in the file COPYING.
# --- SDE-COPYRIGHT-NOTE-END ---

#Description: SquashFS rootfs

rootfs="$build_toolchain/squashfs"
image="$rootfs.sqx"

rm -f "$image"
rm -rf "$rootfs"
mkdir -p "$rootfs"

# Hooks
#
SQUASHFS_POSTINSTALL_HOOK=
SQUASHFS_POSTOVERLAY_HOOK=

# Lists
#
SQUASHFS_INSTALL_PACKAGES=
SQUASHFS_INSTALL_PATTERN="-e '/ boot/d;'"

SQUASHFS_EMPTY_PATTERN="-e '/\.\/lib\/udev\/devices\//d;'"

# source library, and the target specific overlay
#
. "target/share/squashfs.in"
if [ -f target/$target/build-squashfs.in ]; then
	. target/$target/build-squashfs.in
fi

# install what was flisted for stage 1 packages, use $SQUASHFS_INSTALL_PATTERN to skip files
#
[ -n "$SQUASHFS_INSTALL_PACKAGES" ] || SQUASHFS_INSTALL_PACKAGES=$( squashfs_list_packages )

echo_status "Populating ${rootfs#$base/} ..."
for pkg_name in $SQUASHFS_INSTALL_PACKAGES; do
	if squashfs_install "$pkg_name" "build/$SDECFG_ID" "$rootfs"; then
		echo_status "- $pkg_name"

		eval "squashfs_install_flist '$pkg_name' 'build/$SDECFG_ID' '$rootfs' $( squashfs_install_pattern "$pkg_name" "$SQUASHFS_INSTALL_PATTERN" )"
	fi
done

# hook $SQUASHFS_POSTINSTALL_HOOK
#
[ -z "$SQUASHFS_POSTINSTALL_HOOK" ] || eval "$SQUASHFS_POSTINSTALL_HOOK"

# Apply overlay
squashfs_install_overlay "target/$target" "$rootfs"

# hook $SQUASHFS_POSTOVERLAY_HOOK
#
[ -z "$SQUASHFS_POSTOVERLAY_HOOK" ] || eval "$SQUASHFS_POSTOVERLAY_HOOK"

# remove empty directories, use $SQUASHFS_EMPTY_PATTERN to skip directories
#
empty_dir() {
echo_status "Removing empty directories ..."
( cd "$rootfs"; find . -type d ) | tac | eval "sed -e '/\.\/\(dev\|sys\|proc\|mnt\|srv\|tmp\|root\|var\)\(\|\/.*\)$/d;' $SQUASHFS_EMPTY_PATTERN" | while read folder; do
	count=$( find "$rootfs/$folder" | wc -l )

	if [ $count -eq 1 ]; then
		rm -r "$rootfs/$folder"
		# echo_status "- ${folder} deleted."
	fi
done
}

check_symlinks() {
echo_status "Checking for broken symlinks ..."
( cd "$rootfs"; find . -type l | cut -c2- ) | while read link; do
	x="$link"
	case "$link" in
		/dev/*) continue ;;
	esac
	while true; do
		target=$( readlink "$rootfs$x" )
		case "$target" in
			/proc/*)
				continue 2
				;;
			/*)
				;;
			*)
				# relatives turned into absolute
				target="${x%/*}/${target}"
		esac

		[ -L "$rootfs$target" ] || break 1

		x="$target"
	done

	if [ ! -e "$rootfs$target" ]; then
		echo_warning "- $link is broken ($target), deleting."
		rm -f "$rootfs$link"
	fi
done
}

# ldconfig
#
if [ -s "$rootfs/etc/ld.so.conf" ]; then
	echo_status "Running ldconfig ..."
	ldconfig -r "$rootfs"
fi

# sanity checks
#
[ -x "$rootfs/init" ] || echo_warning "This image is missing an /init file, it wont run."
for x in $rootfs/{,usr/}{sbin,bin}/* $rootfs/init $rootfs/lib/udev/*; do
	[ -e "$x" ] || continue

	signature="$( file "$x" 2> /dev/null | cut -d' ' -f2- )"

	case "$signature" in
		directory)	continue ;;
		ASCII\ English\ text)
				continue ;;
		*symbolic*|*statically*|*shell*)
				continue ;;
		*dynamically\ linked*)
				[ "$SDECFG_STATIC" == 1 ] || continue ;;
	esac

	echo_warning "evil signature ($signature) on '${x#$rootfs}'."
done

echo_status "Expanded size: $( du -sh "$rootfs" | cut -f1)."

echo_status "Creating ${rootfs#$base/}.sqx ..."
( mksquashfs $rootfs $image -comp $SDECFG_IMAGE_SQUASHFS_COMP )

echo_status "Image size: $( du -sh "$rootfs.sqx" | cut -f1)."
