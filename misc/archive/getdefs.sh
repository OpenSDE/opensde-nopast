#!/bin/sh
#
# --- T2-COPYRIGHT-NOTE-BEGIN ---
# This copyright note is auto-generated by ./scripts/Create-CopyPatch.
# 
# T2 SDE: misc/archive/getdefs.sh
# Copyright (C) 2004 - 2006 The T2 SDE Project
# Copyright (C) 1998 - 2003 Clifford Wolf
# 
# More information can be found in the files COPYING and README.
# 
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License. A copy of the
# GNU General Public License can be found in the file COPYING.
# --- T2-COPYRIGHT-NOTE-END ---

for x in unix linux i{3,4,5,6}86 alpha powerpc ppc gnuc \
         intel_compiler ; do
	for y in $x __${x}__ _${x}_ __$x _$x ; do
		for z in $y $( echo $y | tr a-z A-Z ) ; do
			echo "X$z $z" >> /tmp/$$.c
		done
	done
done

echo "== ${1:-cc} -E =="
${1:-cc} -E /tmp/$$.c | egrep -xv '(X(.*) \2|#.*)' | \
	cut -c2- | sed 's, ,	,' | expand -t20
rm -f /tmp/$$.c

