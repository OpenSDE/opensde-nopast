# --- SDE-COPYRIGHT-NOTE-BEGIN ---
# This copyright note is auto-generated by ./scripts/Create-CopyPatch.
#
# Filename: lib/sde-download/validate.sh
# Copyright (C) 2006 The OpenSDE Project
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

mkdir -p 'tmp/'
efective=$( $extractor < $gzfile | tee tmp/down.$$.dat | cksum - | cut -f1 -d' ' )

case "$expected" in
	X) echo "Ignoring Checksum ($efective)." ;;
	0) echo "Missing Checksum ($efective)."	;;
	*) if [ "$efective" != "$expected" ]; then
		echo "Wrong Checksum!"
		echo "Moving to $gzfile.cksum-err ($efective)."
		mv "$gzfile" "$gzfile.cksum-err"
		rm tmp/down.$$.dat
		exit 1
	else
		echo "OK."
	fi
esac

case "$format" in
	raw)	mv -f tmp/down.$$.dat "$bzfile"
		;;
	*)	bzip2 < tmp/down.$$.dat > "$bzfile"
		if [ "$gzfile" != "$bzfile" ]; then
			rm -f "$gzfile"
		fi
		rm -f tmp/down.$$.dat
		;;
esac
