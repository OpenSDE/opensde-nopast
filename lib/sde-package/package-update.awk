# --- SDE-COPYRIGHT-NOTE-BEGIN ---
# This copyright note is auto-generated by ./scripts/Create-CopyPatch.
# 
# Filename: lib/sde-package/package-update.awk
# Copyright (C) 2007 The OpenSDE Project
# 
# More information can be found in the files COPYING and README.
# 
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License. A copy of the
# GNU General Public License can be found in the file COPYING.
# --- SDE-COPYRIGHT-NOTE-END ---

{
if ( $0 ~ /^\[V\]/ ) {
	oldver = $2;
	gsub( /\./, "\\.", oldver )
	$2 = ver
	}
else if ( $0 ~ /^\[D\]/ && $3 ~ ".*" oldver ".*" ) {
	filename = $3;
	gsub( oldver, ver, filename );
	if ( filename != $3 ) {
		$2 = 0;
		$3 = filename;
		if ( location == "" )
	  		gsub( oldver, ver, $4 );
		else
	  		$4 = location;
		}
	}


print $0;
}
