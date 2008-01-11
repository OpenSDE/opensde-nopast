# --- SDE-COPYRIGHT-NOTE-BEGIN ---
# This copyright note is auto-generated by ./scripts/Create-CopyPatch.
# 
# Filename: target/share/initramfs/build.sh
# Copyright (C) 2007 - 2008 The OpenSDE Project
# 
# More information can be found in the files COPYING and README.
# 
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License. A copy of the
# GNU General Public License can be found in the file COPYING.
# --- SDE-COPYRIGHT-NOTE-END ---

#Description: Initial ramfs image (cpio.gz) 

rootfs="$build_toolchain/initrd"

rm -rf "$rootfs"
mkdir -p "$rootfs"

# Hooks
#
INITRAMFS_POSTINSTALL_HOOK=
INITRAMFS_POSTOVERLAY_HOOK=

# Lists
#
INITRAMFS_INSTALL_PACKAGES=
INITRAMFS_INSTALL_PATTERN="-e '/ var\/adm/ d;' \
	-e '/\.\(h\|o\|a\|a\..*\|la\|pc\)$/d;' -e '/\/aclocal\//d;' \
	-e '/ usr\/share\/\(doc\|info\|man\)\//d;' -e'/ opt\/[^\/]*\/\(doc\|info\|man\)\//d;' -e '/\/gtk-doc\//d;'"

INITRAMFS_EMPTY_PATTERN="-e '/\.\/lib\/udev\/devices\//d;'"

# source library, and the target specific overlay
#
. "target/share/initramfs.in"
if [ -f target/$target/build-initramfs.in ]; then
	. target/$target/build-initramfs.in
fi

# install what was flisted for stage 1 packages, use $INITRAMFS_INSTALL_PATTERN to skip files
#
[ -n "$INITRAMFS_INSTALL_PACKAGES" ] || INITRAMFS_INSTALL_PACKAGES=$( initramfs_list_stage1 )

echo_status "Populating ${rootfs#$base/} ..."
for pkg_name in $INITRAMFS_INSTALL_PACKAGES; do
	if initramfs_install "$pkg_name" "build/$SDECFG_ID" "$rootfs"; then
		echo_status "- $pkg_name"

		eval "initramfs_install_flist '$pkg_name' 'build/$SDECFG_ID' '$rootfs' $( initramfs_install_pattern "$pkg_name" "$INITRAMFS_INSTALL_PATTERN" )"
	fi
done

# hook $INITRAMFS_POSTINSTALL_HOOK
#
[ -z "$INITRAMFS_POSTINSTALL_HOOK" ] || eval "$INITRAMFS_POSTINSTALL_HOOK"

# Apply overlay
[ ! -d "target/$target/initramfs" ] || initramfs_install_overlay "target/$target/initramfs" "$rootfs"

# remove empty folder, use $INITRAMFS_EMPTY_PATTERN to skip folders
#
echo_status "Removing empty folders ..."
( cd "$rootfs"; find . -type d ) | tac | eval "sed -e '/\.\/\(dev\|sys\|proc\|mnt\|srv\|tmp\|root\|var\)\(\|\/.*\)$/d;' $INITRAMFS_EMPTY_PATTERN" | while read folder; do
	count=$( find "$rootfs/$folder" | wc -l )

	if [ $count -eq 1 ]; then
		rm -r "$rootfs/$folder"
		# echo_status "- ${folder} deleted."
	fi
done

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

echo_status "Creating ${rootfs#$base/}.img ..."
( cd "$rootfs"; find * | cpio -o -H newc ) |
	gzip -c -9 > "$rootfs.img"

echo_status "Image size: $( du -sh "$rootfs.img" | cut -f1)."
