#Description: Initial ramdisk (initrd)

initrddir="$build_toolchain/initrd"

rm -rf "$initrddir"
mkdir -p "$initrddir"

INITRD_POSTFLIST_HOOK=""
INITRD_FLIST_PATTERN="-e '/\.\(h\|o\|a\|la\)$/d;' -e '/ usr\/share\/\(doc\|info\|man\)\//d;'"
INITRD_EMPTY_PATTERN="-e '/\/lib\/udev\/devices\//d;'"

# source target specific code
#
if [ -f target/$target/build-initrd.in ]; then
	. target/$target/build-initrd.in
fi

# install what was flisted for stage 1 packages, use $INITRD_FLIST_PATTERN to skip files
#
echo_status "Populating ${initrddir#$base/} ..."
for pkg_name in $( grep '^X .1' $base/config/$config/packages | cut -d' ' -f5 ); do
	echo_status "- $pkg_name"
	flist="build/${SDECFG_ID}/var/adm/flists/$pkg_name"

	eval "sed -e '/ var\/adm/ d;' $INITRD_FLIST_PATTERN '$flist'" | cut -f2- -d' ' |
		tar -C "build/${SDECFG_ID}/" -cf- --no-recursion --files-from=- |
		tar -C "$initrddir" -xf-
done

# hook
#
[ -z "$INITRD_POSTFLIST" ] || eval "$INITRD_POSTFLIST"

# remove empty folder, use $INITRD_EMPTY_PATTERN to skip folders
#
echo_status "Removing empty folders ..."
find "$initrddir" -type d | tac | eval "sed -e '/\/dev\$/d;' $INITRD_EMPTY_PATTERN" | while read folder; do
	count=$( find "$folder" | wc -l )

	if [ $count -eq 1 ]; then
		rm -r "$folder"
		#echo_status "- ${folder#$initrddir} deleted."
	fi
done

echo_status "Expanded size: $( du -sh "$initrddir" | cut -f1)."

echo_status "Creating ${initrddir#$base/}.img ..."
( cd "$initrddir"; find * | cpio -o -H newc ) |
	gzip -c -9 > "$initrddir.img"

echo_status "Image size: $( du -sh "$initrddir.img" | cut -f1)."