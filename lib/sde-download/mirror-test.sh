# --- SDE-COPYRIGHT-NOTE-BEGIN ---
# This copyright note is auto-generated by ./scripts/Create-CopyPatch.
#
# Filename: lib/sde-download/mirror-test.sh
# Copyright (C) 2006 - 2008 The OpenSDE Project
#
# More information can be found in the files COPYING and README.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License. A copy of the
# GNU General Public License can be found in the file COPYING.
# --- SDE-COPYRIGHT-NOTE-END ---

maxspeed=0 mirror=

[ -n "$SDEROOT" ] ||
	export SDEROOT=$( cd "${0%/*}/../.."; pwd -P )

. $SDEROOT/lib/libsde.in

OLDIFS="$IFS" IFS=":"
while read name country admin url ; do
	# translate $country
	case "$country" in
		cl)	country="Chile"	;;
		cr)	country="Costa Rica"	;;
		de)	country="Germany"	;;
		my)	country="Malaysia"	;;
	esac

	# no trailing /
	url="${url%/}"

	# test
	echo -n "Testing <$name> ($country) ..." 1>&2
	speed="$(curl -s -m 20 "$url/DOWNTEST" -w "%{speed_download}" -o /dev/null |
		sed -e 's:,:.:' -e 's:[\.,]...$::' )"

	# compare
	if [ "${speed:-0}" = "0" ]; then
		echo ' failed' 1>&2
	else
		echo " $speed B/s" 1>&2
		# and make a choice
		if [ "$speed" -gt "$maxspeed" ]; then
			maxspeed="$speed"; mirror="$url"
		fi
	fi
done < <( sed -e '/^#/d;' $1 )
IFS="$OLDIFS"

[ -n "$mirror" ] || mirror=broken

$SDEROOT/bin/sde-config-ini -F "$SDESETTINGS" "download-$sdever.mirror=$mirror"
