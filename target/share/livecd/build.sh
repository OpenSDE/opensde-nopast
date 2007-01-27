# --- T2-COPYRIGHT-NOTE-BEGIN ---
# This copyright note is auto-generated by ./scripts/Create-CopyPatch.
# 
# T2 SDE: target/share/livecd/build.sh
# Copyright (C) 2004 - 2006 The T2 SDE Project
# 
# More information can be found in the files COPYING and README.
# 
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License. A copy of the
# GNU General Public License can be found in the file COPYING.
# --- T2-COPYRIGHT-NOTE-END ---
#
#Description: Live CD

isofsdir="$build_toolchain/isofs"		# for the ISO9660 content
imagelocation="$build_toolchain/rootfs"	# where the roofs is prepared and sq.

# create the live initrd's first
. $base/target/share/livecd/build_initrd.sh
. $base/target/share/livecd/build_image.sh

# TODO: make arch specific and such ... rushed out in a hurry right now

cat > $build_toolchain/isofs.txt <<- EOT
BOOT	-b boot/grub/stage2_eltorito -no-emul-boot
BOOTx	-boot-load-size 4 -boot-info-table
DISK1	build/${SDECFG_ID}/TOOLCHAIN/isofs /
EOT

echo_status "Done!"

