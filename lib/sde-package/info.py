import time
base="http://packages.debian.org"
distro="stable"
usage ="""sde pkg new --deb [options] arg 
example: sde pkg new -deb -o network/apache2 apache2
Run --help (-h) for more info"""
force=True
guess=True
def copynote(package):
	return """[COPY] --- SDE-COPYRIGHT-NOTE-BEGIN ---
[COPY] This copyright note is auto-generated by ./scripts/Create-CopyPatch.
[COPY] 
[COPY] Filename: package/.../%(p)s/%(p)s.desc
[COPY] Copyright (C) %(t)s The OpenSDE Project
[COPY] 
[COPY] More information can be found in the files COPYING and README.
[COPY] 
[COPY] This program is free software; you can redistribute it and/or modify
[COPY] it under the terms of the GNU General Public License as published by
[COPY] the Free Software Foundation; version 2 of the License. A copy of the
[COPY] GNU General Public License can be found in the file COPYING.
[COPY] --- SDE-COPYRIGHT-NOTE-END ---""" %{ "p": package,
't': time.strftime('%Y')} 
desci="[I] TODO: Short Information"
desct="""TODO: Long Explanation
TODO: Long Explanation
TODO: Long Explanation
TODO: Long Explanation
TODO: Long Explanation"""
descu="[U] TODO: URL"
desca="[A] TODO: Author"
descm="[M] The OpenSDE Community <list@opensde.org>"
descc="[C] TODO: Category"
descl="[L] TODO: License"
descs="[S] TODO: Status"
descv="[V] TODO: Version"
descp="[P] X -----5---9 800.000"
descd="[D] 0"
status={"oldstable":"stable",
"stable":"Stable",
"testing":"Gamma",
"unstable":"Beta",
"experimental":"Alpha"}

licenses={"contrib":"OpenSource",
			"Non-Free":"Free-to-use",
			"Non-US/Main":"Free-to-use",
			"Non-US/Non-Free":"OpenSource"}
categories={"admin":"extra/tool",
				"comm":"extra/network",
				"debian-installer":"extra/base",
				"doc":"extra/documentation",
				"editors":"extra/editor",
				"electronics":"extra/tool",
				"embedded":"extra/embedded",
				"games":"extra/game",
				"gnome":"extra/desktop/gnome",
				"graphics":"extra/graphic",
				"hamradio":"extra/tool",
				"interpreters":"extra/shell",
				"kde":"extra/desktop/kde",
				"libdevel":"extra/development",
				"libs":"extra/library",
				"mail":"extra/office",
				"math":"extra/scientific",
				"misc":"extra/miscellaneous",
				"net":"extra/network",
				"news":"extra/office",
				"oldlibs":"extra/library",
				"otherosfs":"extra/tools",
				"perl":"extra/development",
				"python":"extra/development",
				"science":"extra/scientific",
				"shells":"extra/shell",
				"tex":"extra/text",
				"text":"extra/text",
				"utils":"extra/tool",
				"web":"extra/network",
				"x11":"extra/x11"
				}
				# category exlucsion:reason 
debianpolicy="http://www.debian.org/doc/debian-policy/ch-binary"
excludecat={"virtual":"""
							This is a debian only package.
							See %s#s-virtual_pkg for reason"""% debianpolicy
				}