#!/bin/sh
# --- SDE-COPYRIGHT-NOTE-BEGIN ---
# This copyright note is auto-generated by ./scripts/Create-CopyPatch.
#
# Filename: lib/sde-download/protocols/git.sh
# Copyright (C) 2007 - 2008 The OpenSDE Project
#
# More information can be found in the files COPYING and README.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License. A copy of the
# GNU General Public License can be found in the file COPYING.
# --- SDE-COPYRIGHT-NOTE-END ---

[ -n "$SDEROOT" ] ||
	export SDEROOT=$( cd "${0%/*}/.."; pwd -P )

. "$SDEROOT/lib/libsde.in"

download_usage() {
	local progname=${0##*/}
	cat <<EOT >&2
Usage:	$progname [-vq] <target> <source> <tag>
EOT
}

shortopts='qv'
longopts='quiet,verbose'
options=$( getopt -o "$shortopts" -l "$longopts" -- "$@" )

if [ $? -ne 0 ]; then
	download_usage
	exit -1
fi

# load new arguments list
eval set -- "$options"

verbose=1
target=
source=

while [ $# -gt 0 ]; do
	case "$1" in
		--)	shift; break ;;

		-v|--verbose)
			let verbose++ ;;
		-q|--quiet)
			let verbose-- ;;
	esac
	shift
done

# now take the real arguments
if [ $# -ne 3 ]; then
	echo_error "Not enough arguments given."
	download_usage
	exit -1
fi

target="$1"
source="$2"
tag="$3"
errno=0

if [ -e "$target.lock" ]; then
	echo_warning "$target: File locked"
	exit 111
else
	trap '' INT
	echo "$$" > "$target.lock"
	prefix=${source##*/}; prefix=${prefix%.git}-${tag}

	[ $verbose -le 1 ] || echo_info "git-archive --format=tar --prefix=$prefix/ --remote='$source' '$tag'"

	# download in background
	(
	git-archive --format=tar --prefix=$prefix/ --remote="$source" "$tag" | bzip2 > $target
	echo $? > $target.errno
	) &

	# and wait until it ends
	while fuser $target &> /dev/null ; do
		$ECHO_E -n "$( nice du -sh "$target" 2> /dev/null | cut -f1 ) downloaded from archive so far...\r"
		sleep 3
	done

	errno=$( cat $target.errno 2> /dev/null )
	if [ "$errno" != "0" -o ! -s "$target" ]; then
		rm -f "$target"
		echo_error "Download failed (errno:${errno:-undefined})"
	elif [ $verbose -gt 0 ]; then
		echo_info "$( du -sh "$target" 2> /dev/null | cut -f1 ) downloaded from archive."
	fi

	rm -f "$target.errno" "$target.lock"
	trap - INT
	exit ${errno:-1}
fi
