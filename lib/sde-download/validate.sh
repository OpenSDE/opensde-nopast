# --- SDE-COPYRIGHT-NOTE-BEGIN ---
# This copyright note is auto-generated by ./scripts/Create-CopyPatch.
#
# Filename: lib/sde-download/validate.sh
# Copyright (C) 2006 - 2011 The OpenSDE Project
#
# More information can be found in the files COPYING and README.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License. A copy of the
# GNU General Public License can be found in the file COPYING.
# --- SDE-COPYRIGHT-NOTE-END ---

if [ $# -ne 3 ]; then
	echo "Usage: $0 <original> <ours> <checksum>"
	exit 2
fi

gzfile="$1"
bzfile="$2"
expected="$3"

if [ ! -f "$gzfile" ]; then
	echo "File '$gzfile' not found."
	exit 1
fi

# extractor
case "${gzfile##*.}" in
	bz2|tbz2|tbz)
		format=bzip2
		extractor=bunzip2 ;;
	gz|tgz) format=gzip
		extractor=gunzip ;;
	xz)	format=xz
		extractor=unxz ;;
	tar)	format=tar
		extractor=cat ;;
	Z)	format=Z
		extractor=uncompress
		# gunzip may be an alternative for uncompress
		if ! type -p $uncompress 2>&1 > /dev/null; then
			extractor=gunzip
		fi ;;
	*)	format=raw
		extractor=cat ;;
esac

echo -n "cksum-test ($format): $gzfile... "

if [ "$bzfile" = "$gzfile" ]; then
	tmpfile=
	effective=$( $extractor < $gzfile | cksum - | cut -f1 -d' ' )
else
	mkdir -p 'tmp/'
	tmpfile="tmp/down.$$.dat"
	effective=$( $extractor < $gzfile | tee "$tmpfile" | cksum - | cut -f1 -d' ' )
fi

case "$expected" in
	X) echo "Ignoring Checksum ($effective)." ;;
	0) echo "Missing Checksum ($effective)." ;;
	*) if [ "$effective" != "$expected" ]; then
		echo "Wrong Checksum!"
		echo "Moving to $gzfile.cksum-err ($effective)."
		mv "$gzfile" "$gzfile.cksum-err"
		[ -z "$tmpfile" ] || rm -f "$tmpfile"
		exit 1
	else
		echo "OK."
	fi
esac

if [ -n "$tmpfile" ]; then
	case "$format" in
	raw)	mv -f "$tmpfile" "$bzfile"
		;;
	*)	bzip2 < "$tmpfile" > "$bzfile"
		rm -f "$gzfile" "$tmpfile"
		;;
	esac
fi
