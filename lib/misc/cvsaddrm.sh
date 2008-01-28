#!/bin/sh
# --- SDE-COPYRIGHT-NOTE-BEGIN ---
# This copyright note is auto-generated by ./scripts/Create-CopyPatch.
# 
# Filename: lib/misc/cvsaddrm.sh
# Copyright (C) 2008 The OpenSDE Project
# Copyright (C) 2004 - 2006 The T2 SDE Project
# 
# More information can be found in the files COPYING and README.
# 
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License. A copy of the
# GNU General Public License can be found in the file COPYING.
# --- SDE-COPYRIGHT-NOTE-END ---

tmp1=`mktemp`
tmp2=`mktemp`

find -type d -name CVS | while read dirname ; do
	echo ${dirname%/*}
	awk -F "/" '$1 == "" && $3 !~ /^-/ {
		print "'"${dirname%/*}"'/" $2; }' < $dirname/Entries
done | sed 's,./,,' | sort > $tmp1

find | grep -v '/CVS' | grep -v '/\.$' | sed 's,./,,' | sort > $tmp2

diff -u0 $tmp1 $tmp2 | grep '^[-+][A-Za-z]' | \
	egrep -xv '\+Documentation/(FAQ|LSM)' | \
	sed 's,^-,cvs remove ,; s,^+,cvs add    ,'

rm -f $tmp1 $tmp2
