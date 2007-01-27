#!/bin/bash
#
# --- SDE-COPYRIGHT-NOTE-BEGIN ---
# This copyright note is auto-generated by ./scripts/Create-CopyPatch.
# 
# Filename: lib/sde-package/patch-update.sh
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

pkg="$1" ; shift
ver="$1" ; shift

if [ -z "$ver" ]; then
	ver=${pkg/*-/}
	pkg=${pkg%-$ver}
fi

if [ -z "$pkg" -o -z "$ver" ]; then
        echo "Usage: $0 pkg ver"
        echo "   or: $0 pkg-ver"
        exit
fi

pkg=`echo $pkg | tr A-Z a-z`

echo "[ $pkg ]" >&2
pkgdir=`echo package/*/$pkg`

if [ ! -d "$pkgdir" ] ; then
        echo "Can't find package for '$x'!" >&2
else
	oldver="`egrep "^\[(V|VER|VERSION)\] " $pkgdir/$pkg.desc |
			tr '\t' ' ' | tr -s ' ' | cut -f2 -d' '`"
	tmpfile=`mktemp` ; tmpfile2=`mktemp`
	echo "Update patch for $pkg ($pkgdir): $oldver -> $ver"

	# [V]
 	expression="-e 's,^\[\(V\|VER\|VERSION\)\].*,[\1] $ver,'"
	# file at [D]
	expression="$expression -e '/^\[\(D\|DOWN\|DOWNLOAD\)\]/ s,${oldver//./\\.},$ver,g;'"

	# detect download location structure
	sed -n -e 's,^\[\(D\|DOWN\|DOWNLOAD\)\].*[ \t]\([^ \t]*\)[ \t]*$,\2,p' $pkgdir/$pkg.desc > $tmpfile

	if grep -q "/$oldver/$" $tmpfile; then
		# $ver -> /$ver/
		oldver="${oldver//./\\.}"
		expression="$expression -e '/^\[\(D\|DOWN\|DOWNLOAD\)\]/ s,/$oldver/[ \t]*\$,/$ver/,g;'"
	elif [ "$oldver" != "${oldver//-/}" ] && grep -q "/${oldver//-/}/\$" $tmpfile; then
		# $ver-$extra -> /$ver/
		oldver="${oldver%%-*}"; oldver="${oldver//./\\.}"
		ver="${ver%%-*}"
		expression="$expression -e '/^\[\(D\|DOWN\|DOWNLOAD\)\]/ s,/$oldver/[ \t]*\$,/$ver/,g;'"
	else
		# $ver.$extra -> /$ver/
		oldver="${oldver%%-*}"
		ver="${ver%%-*}"

		oldauxver=
		auxver=
		pattern="[^\.]*"
		while [ "${oldver#$oldauxver}" ]; do
			eval $( echo "$oldver $ver" | sed -e "s,\($pattern\).* \($pattern\).*,oldauxver=\1 auxver=\2," )
			if grep -q "/$oldauxver/\$" $tmpfile; then
				oldver="${oldauxver%%-*}"; oldauxver="${oldauxver//./\\.}"
				ver="${auxver%%-*}"
				expression="$expression -e '/^\[\(D\|DOWN\|DOWNLOAD\)\]/ s,/$oldver/[ \t]*\$,/$ver/,g;'"
				break
			fi
			pattern="$pattern\.\?[^\.]*"
		done
	fi

	# checksum at [D]
	expression="$expression -e 's,^\[\(D\|DOWN\|DOWNLOAD\)\] [0-9]\+,[\1] 0,'"

	eval "sed $expression $pkgdir/$pkg.desc" > $tmpfile
	diff -u ./$pkgdir/$pkg.desc $tmpfile | tee $tmpfile2
	[ -s $tmpfile2 ] || echo "Patch for '$x' is empty!" >&2
	rm -f $tmpfile $tmpfile2
fi
echo

