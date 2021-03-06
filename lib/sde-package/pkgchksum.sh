#!/bin/sh
# --- SDE-COPYRIGHT-NOTE-BEGIN ---
# This copyright note is auto-generated by ./scripts/Create-CopyPatch.
#
# Filename: lib/sde-package/pkgchksum.sh
# Copyright (C) 2006 - 2008 The OpenSDE Project
# Copyright (C) 2004 - 2006 The T2 SDE Project
# Copyright (C) 1998 - 2003 Clifford Wolf
#
# More information can be found in the files COPYING and README.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License. A copy of the
# GNU General Public License can be found in the file COPYING.
# --- SDE-COPYRIGHT-NOTE-END ---

# This routine generates the package checksum of a $confdir.
# The checksum includes the filenames and content (except of the .cache),
# including subdirs but without whitespaces and comments and some tag lines
# that are not vital for rebuilds during update checks.

if [ -d "$1" ]; then
	cd "$1"

	# find all files (without hidden (e.g. .svn) files)
	find . ! -path '*/.*' ! -name '*.cache' -print -exec cat \{\} \; \
	2>/dev/null |
	# strip some unimportant stuff (e.g. comments, whitespaces, ...)
	sed \
	-e '/^[ ]*#.*/d' \
	-e '/^\[COPY\]/d' \
	-e '/^\[CV-*\]/d' \
	-e '/^\[[T,I,U,A,M,L,S,C]\]/d' \
	-e 's/[\t ]*//g' \
	-e '/^ *$/d' |
	md5sum | cut -d ' ' -f 1
else
	exit 1
fi
