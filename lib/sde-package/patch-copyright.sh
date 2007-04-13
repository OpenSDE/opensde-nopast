#!/bin/sh
# --- SDE-COPYRIGHT-NOTE-BEGIN ---
# This copyright note is auto-generated by ./scripts/Create-CopyPatch.
# 
# Filename: lib/sde-package/patch-copyright.sh
# Copyright (C) 2006 - 2007 The OpenSDE Project
# Copyright (C) 2004 - 2005 The T2 SDE Project
# Copyright (C) 1998 - 2003 Clifford Wolf
# 
# More information can be found in the files COPYING and README.
# 
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License. A copy of the
# GNU General Public License can be found in the file COPYING.
# --- SDE-COPYRIGHT-NOTE-END ---

# must match [^-]*-COPYRIGHT-NOTE
NOTEMARKER=SDE-COPYRIGHT-NOTE
PROJECTNAME="The OpenSDE Project"

copynote=`mktemp`
copynotepatch=`mktemp`
rocknote=`mktemp`
oldfile=`mktemp`
newfile=`mktemp`
tmpfile=`mktemp`

thisyear=`date +%Y`

cat << EOT > $copynote
This copyright note is auto-generated by ./scripts/Create-CopyPatch.

Filename: @@FILENAME@@
@@COPYRIGHT@@

More information can be found in the files COPYING and README.

EOT

cp $copynote $copynotepatch

cat << EOT >> $copynote
This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; version 2 of the License. A copy of the
GNU General Public License can be found in the file COPYING.
EOT

cat << EOT >> $copynotepatch
This patch file is dual-licensed. It is available under the license the
patched project is licensed under, as long as it is an OpenSource license
as defined at http://www.opensource.org/ (e.g. BSD, X11) or under the terms
of the GNU General Public License as published by the Free Software
Foundation; either version 2 of the License, or (at your option) any later
version.
EOT

if [ $# = 0 ]; then
    set lib/. architecture/. misc/. package/. scripts/. target/.
else
    # check if file or package name was given
    files=""
    for i; do
	if [ -f $i -o -d $i ]; then
	    files="$files ${i#./}"
	elif [ -d package/*/$i ]; then
	    for each in `echo package/*/$i`; do
		[[ $each = *~ ]] && continue
		files="$files $each/."
	    done
	else
	    echo Cannot find \'$i\', ignoring. 1>&2
	fi
    done
    set -- $files 
    [ $# = 0 ] && exit
fi

bash scripts/xfind.sh $* -type f ! -name "*~" \
	| sed 's,/\./,/,g' |
while read filename ; do

	grep -q -e '--- NO-[^-]*-COPYRIGHT-NOTE ---' "$filename" &&
		continue

	# detect current copyright note tag
	tag=$( sed -n -e "/^\(.*\)--- \([^-]*\)-COPYRIGHT-NOTE-BEGIN ---.*/{s//\1/;p;q;}" "$filename" )
	pretag= posttag=

	has_copyright_note=1
	if [ "$tag" = "# " ]; then
		mode=sh
	elif [ "$tag" = "[COPY] " ]; then
		mode=asci
	elif [ "$tag" = " * " ]; then
		pretag='/*' posttag=' */'
		mode=c
	elif [ "$tag" = "dnl " ]; then
		mode=m4
	elif [ "$tag" = "-- " ]; then
		mode=lua
	elif [ -z "$tag" ]; then
		has_copyright_note=0
		# determine the comment mode by extension
		mode=none
		case "$filename" in
			*.cache) continue ;;
			*/Makefile|*.sh|*.pl|*.in|*.hlp|*.conf) mode=sh ;;
			*.cron|*.postinstall|*.init) mode=sh ;;
			*.h|*.c|*.lex|*.y|*.spec|*.tcx|*.tmpl|*.tcc) mode=c ;;
			*.lua) mode=lua ;;
			*.desc) mode=asci ;;
			*scripts/[A-Z][a-z-]*|*/parse-config*) mode=sh ;;
			*.patch|*.diff|*.patch.*|*.patch-*) mode=sh ;;
			*m4) mode=m4 ;;
		esac

		#echo "Mode type: $mode"

		case "$mode" in
			none)	if head -n 1 "$filename" | grep -q '^#!'; then
					mode=sh
					tag="# "
				else
					echo "Unknown type of $filename"
					continue
				fi
				;;
			sh)	tag="# "
				;;
			asci)	tag="[COPY] "
				;;
			m4)	tag="dnl "
				;;
			lua)	tag="-- "
				;;
			c)	pretag='/*' posttag=' */'
                		tag=' * '
				;;
			*)	echo "Unknown mode '$mode' of $filename"
				continue
				;;
		esac
	else
		echo "Unknown tag '$tag' on $filename"
		continue
	fi

	# make a copy in the case we have no matching conditional below
	sed -e "s,--- \([^-]*\)-COPYRIGHT-NOTE-\(BEGIN\|END\) ---,--- $NOTEMARKER-\2 ---,g" \
		"$filename" > $oldfile

	if [ $has_copyright_note -eq 1 ]; then
		# has a note, catch copyrights

		oldcopyright=`sed -e "/--- $NOTEMARKER-BEGIN ---/,/--- $NOTEMARKER-END ---/!d" \
		 	-e '/.*\(Copyright (C) .*\)/!d;s//\1/;' \
			$oldfile`
	else
		oldcopyright=
	fi

	if echo "$oldcopyright" | grep -q "$PROJECTNAME"; then
		# A copyright note from our project was found, renew if necesary
		since=$( echo "$oldcopyright" | sed -n -e "s,.* (C) \([^ ]*\) .*$PROJECTNAME.*,\1,p" )

		if [ $since -lt $thisyear ]; then
			copyright=`echo "$oldcopyright" | sed -e \
			"s,.*$PROJECTNAME.*,Copyright (C) $since - $thisyear $PROJECTNAME,"`
		else
			copyright=`echo "$oldcopyright" | sed -e \
			"s,.*$PROJECTNAME.*,Copyright (C) $thisyear $PROJECTNAME,"`
		fi
	else
		# else, add one...
		copyright="Copyright (C) $thisyear $PROJECTNAME"
		copyright="$copyright${oldcopyright:+\\n$oldcopyright}"
	fi

	if [ $has_copyright_note -ne 1 ]; then
		# doesn't have a note
		if head -n 1 "$filename" | grep -q '^#!'; then
			action='a'
		else
			action='i'
		fi

		# insert one
		sed -i "1 $action\\
${pretag:+$pretag\\
}$tag--- $NOTEMARKER-BEGIN ---\\
$tag--- $NOTEMARKER-END ---\\
${posttag:+$posttag\\
}" $oldfile
	fi

	mangled_filename=`echo "$filename" | \
		sed 's,package/\([^/]*\)/\(.*\),package/.../\2,'`

	#echo BEFORE
	#cat $oldfile

	if [ "$tag" ] ; then
	    # implant our copy note
	    {
		grep -B 100000 -- "--- $NOTEMARKER-BEGIN ---" $oldfile
		{
		if [ "$filename" != "${filename%/*.diff}" -o \
		     "$filename" != "${filename%/*.patch}" -o \
		     "$filename" != "${filename%/*.patch.*}" -o \
		     "$filename" != "${filename%/*.patch-*}" ] ; then
			sed -e "s,@@FILENAME@@,$mangled_filename,; \
				s,@@COPYRIGHT@@,${copyright//
/\n},;"  $copynotepatch
		else
			sed -e "s,@@FILENAME@@,$mangled_filename,; \
				s,@@COPYRIGHT@@,${copyright//
/\n},;"  $copynote
		fi
		# we need a separated sed call because $rockcopyright adds a new line
		} | sed -e "s,^,$tag,"

		grep -A 100000 -- "--- $NOTEMARKER-END ---" $oldfile
	    } > $newfile

	    # create the difference
	    if ! cmp -s $oldfile $newfile ; then
		echo "Creating patch for $filename." >&2
		diff -u "./$filename" $newfile |
			sed -e "2 s,$newfile,./$filename,"
	    fi
	else
		echo "WARNING: No Copyright tags in $filename found!" >&2
	fi
done

rm -f $copynote $copynotepatch $newfile

