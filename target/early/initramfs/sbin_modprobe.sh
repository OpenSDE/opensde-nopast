#!/bin/sh
# --- SDE-COPYRIGHT-NOTE-BEGIN ---
# This copyright note is auto-generated by ./scripts/Create-CopyPatch.
#
# Filename: target/early/initramfs/sbin_modprobe.sh
# Copyright (C) 2007 - 2010 The OpenSDE Project
#
# More information can be found in the files COPYING and README.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License. A copy of the
# GNU General Public License can be found in the file COPYING.
# --- SDE-COPYRIGHT-NOTE-END ---
for x; do
	if [ "$x" != "-b" ]; then
		args="$args $x";
	fi
done
export PATH
LOG="/var/log/modprobe.log"
echo "[$$] modprobe $*" >> "$LOG"
exec /bin/busybox modprobe $args 2>&1 | tee -a "$LOG" >&2

