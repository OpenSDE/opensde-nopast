#!/bin/sh
#
# --- SDE-COPYRIGHT-NOTE-BEGIN ---
# This copyright note is auto-generated by ./scripts/Create-CopyPatch.
#
# Filename: lib/misc/cvsmv.sh
# Copyright (C) 2008 The OpenSDE Project
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

if [ "$1" = "rm" ] ; then
	find $2 -type f ! -path '*/CVS/*' | xargs rm -vf
elif [ "$1" = "mv" -o "$1" = "cp" ] ; then
	find $2 -type d ! -name CVS -printf "$3/%P\n" | xargs mkdir -p
	find $2 -type f ! -path '*/CVS/*' -printf "$1 -v %p $3/%P\n" | sh
else
	echo "Usage: $0 mv source-dir target-dir"
	echo "Usage: $0 cp source-dir target-dir"
	echo "   or: $0 rm remove-dir"
	exit 1
fi

