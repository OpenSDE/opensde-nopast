#!/bin/sh
# --- SDE-COPYRIGHT-NOTE-BEGIN ---
# This copyright note is auto-generated by ./scripts/Create-CopyPatch.
# 
# Filename: lib/sde-package/package-gem.sh
# Copyright (C) 2007 The OpenSDE Project
# 
# More information can be found in the files COPYING and README.
# 
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License. A copy of the
# GNU General Public License can be found in the file COPYING.
# --- SDE-COPYRIGHT-NOTE-END ---

. lib/libsde.in

pkg_name=
versioned=
root=

usage() {
cat <<EOT
Creates a GEM file for a given package based on it's flist

Usage: ${0} [--versioned] [--root <root>] [--output <output>] <package>
	root	location of the root of the sandbox
	output	folder to place the binary packages
	package	name of the package

	--versioned	use package version in the resulting file name
EOT
}

while [ $# -gt 0 ]; do
	case "$1" in
		--versioned)	versioned=1 ;;
		--root)		root="$2"; shift ;;
		--output)	output="$2"; shift ;;
		--*)		usage; exit 1 ;;
		*)		if [ "$pkg_name" ]; then
					usage; exit 1
				else
					pkg_name="$1"
				fi ;;
	esac
	shift
done

if [ -z "$pkg_name" ]; then
	usage; exit 1
elif [ ! -r "${root}/var/adm/packages/$pkg_name" ]; then
	echo_error "package '$pkg_name' not found."
	exit 2
elif [ "$versioned" ]; then
	version=$( grep '^Package Name and Version:' "${root}/var/adm/packages/$pkg_name" | cut -f6 -d' ' )
	if [ -z "$version" ]; then
		echo_error "package '$pkg_name' is broken."
		exit 2
	fi
else
	version=
fi

output="${output:-.}"
filename="${pkg_name}${versioned:+-${version}}"

if $SDEROOT/lib/sde-package/package.sh --type "tar.bz2" ${versioned:+--versioned} --root "${root}" \
	--output "${output}" "${pkg_name}"; then
	echo_status "Converting $filename.tar.bz2 into GEM format"

	mine -C "${root}/var/adm" "$output/$filename.tar.bz2" "$pkg_name" \
		"$output/$filename.gem.tmp"
	errno=$?
	if [ "$?" != 0 ]; then
		echo_error "Failed to create '$output/$filename.gem'"
		rm -f "$output/$filename.gem.tmp"
	else
		mv "$output/$filename.gem"{.tmp,}
	fi

	echo_status "Removing temporary ${filename}tar.bz2 file"
	rm -f "$output/$filename.tar.bz2"

	exit $errno
fi
