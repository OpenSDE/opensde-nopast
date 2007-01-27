#!/bin/sh
# --- SDE-COPYRIGHT-NOTE-BEGIN ---
# This copyright note is auto-generated by ./scripts/Create-CopyPatch.
# 
# Filename: misc/archive/fixmaintainer.sh
# Copyright (C) 2006 The OpenSDE Project
# Copyright (C) 2004 - 2006 The T2 SDE Project
# 
# More information can be found in the files COPYING and README.
# 
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License. A copy of the
# GNU General Public License can be found in the file COPYING.
# --- SDE-COPYRIGHT-NOTE-END ---

if [ "$1" == "-count" ]; then
	grep '^\[M\]' package/*/*/*.desc | cut -d' ' -f2- | sort -u | \
		while read maintainer; do
			echo -n "-> '$maintainer' ..."
			count=$( grep -l "^\[M\] $maintainer\$" package/*/*/*.desc | wc -l )
			echo " $count."
		done
elif [ "$1" == "-list" ]; then
	grep '^\[M\]' package/*/*/*.desc | cut -d' ' -f2- | sort -u | sed -e "s,^\(.*\)$,'\1',"
elif [ $# -eq 2 ]; then
	echo "	* changed '$1' packages to '$2'" >> commit-fixmaintainer.txt
	echo "changing '$1' to '$2'..."
	for x in `grep -l "^\[M\] $1[ \t]*$" package/*/*/*.desc`; do
		echo "-> $x"
		sed -i -e "s,^\[M\] $1[ \t]*\$,[M] $2," $x
	done
else
	echo "Usage: $0 (-list|-count)"
	echo "       $0 <old> <new>"
fi
