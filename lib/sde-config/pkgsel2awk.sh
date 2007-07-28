#!/bin/bash
# --- SDE-COPYRIGHT-NOTE-BEGIN ---
# This copyright note is auto-generated by ./scripts/Create-CopyPatch.
# 
# Filename: lib/sde-config/pkgsel2awk.sh
# Copyright (C) 2006 - 2007 The OpenSDE Project
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

# Convert a pkg selection rule into awk format
#

# Example:
#   pkgsel X python
#     Result: ( / [^/]*\/python / ) { $1="X"; }
#   pkgsel "O perl/*" 
#     Result: ( / perl\/[^/]* / ) { $1="O"; }
#   pkgsel_parse < config/${config}/pkgsel
#     Result: creates pkgsel.awk output
#   pkgsel include file
#     Result: continues processing file specified
pkgsel_parse() {
	local action patterlist pattern
	local address first others

	sed -e '/^#/d;' -e '/^[ \t]*$/d;' "$@" | while read action patternlist ; do
 		case "$action" in
		    [xX])
			action='$1="X"' ;;
		    [oO])
			action='$1="O"' ;;
		    -)
			action='next'   ;;
		    =)
			action='$1=def' ;;
		    include)
		        pkgsel_parse $patternlist
			continue ;;
		    *)
			echo '{ exit; }'
			continue ;;
		esac
		address=""
		while read xpattern ; do
			pattern="${xpattern#\!}"
			[ "$pattern" = "$xpattern" ]; neg=$?
			[ "${pattern}" = "${pattern//\//}" ] && pattern="*/$pattern"
			pattern="$( echo "$pattern" | sed \
			            -e 's,[^a-zA-Z0-9_/\*+\-\[\]],,g' \
			            -e 's,[/\.\+],\\\\&,g' \
			            -e 's,\*,[^/]*,g' )"

			[ -z "$address" ] || address="$address &&"

			if [ $neg -eq 0 ]; then
				address="$address( \$5 ~ \"^${pattern}\$\" )"
			else
				address="$address( \$5 !~ \"^${pattern}\$\" )"
			fi
		done < <( echo "$patternlist" | tr '\t ' '\n\n' )
		echo "{ if ( $address ) { $action; } }"
	done
}

cat <<EOF
{ 
  def=\$1 ;
  repo=\$4 ;
  pkg=\$5 ;
  \$5 = \$4 "/" \$5 ;
  \$4 = "placeholder" ;
}
EOF

pkgsel_parse "$@"

cat <<EOF
{ 
  \$4=repo ;
  \$5=pkg ;
  print ;
}
EOF
