#!/usr/bin/perl -w
#
# --- SDE-COPYRIGHT-NOTE-BEGIN ---
# This copyright note is auto-generated by ./scripts/Create-CopyPatch.
#
# Filename: lib/misc/split-patch.pl
# Copyright (C) 2008 The OpenSDE Project
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

use strict;
use English;

open(F,">/dev/null") || die $!;

while (<>) {
	next if /^diff /;
	if (/^--- (\S+)\s/) {
		my $fn=$1; $fn=~s,/,:,g;
		$fn=~s,^[^:]+:,,; $fn.=".patch";
		print "Writing $fn ...\n";
		close(F); open(F,">$fn") || die $!;
	}
	print F;
}

close(F);
