#!/bin/bash

dest=$(readlink -f .)
basename=$(basename "$dest")
basenameset=

prefix=
windowopt=
window=

usage ()
{
	echo 'Usage: $0 [<options>]' >&2
	echo 'Options:' >&2
	echo '  -h, --help                Print this usage' >&2
	echo '  -p, --prefix string       Specify optional prefix to use for output file names' >&2
	echo '  -b, --basename string     Specify base name to use for output file names ['"$basename"']' >&2
	echo '  -d, --dest directory      Specify target directory name to use for output files ['"$dest"']' >&2
	echo '  -i, --window-id string    Specify window resource ID to dump instead of default screen' >&2
	echo '  -w, --window-name string  Specify window WM_NAME to dump instead of default screen' >&2
}

TEMP=$(getopt -o 'hp:b:d:i:w:' --long 'help,prefix:,basename:,dest:,window-id:,window-name:' -n "$0" -- "$@")
if [ $? -ne 0 ]; then
	usage
	exit 1
fi
eval set -- "$TEMP"
unset TEMP
printhelp=
while true; do
	case "$1" in
		'-h'|'--help')
			printhelp=1
			shift
			continue
		;;
		'-p'|'--prefix')
			shift
			prefix="$1"
			shift
			continue
		;;
		'-b'|'--basename')
			shift
			basename="$1"
			basenameset=1
			shift
			continue
		;;
		'-d'|'--dest')
			shift
			dest=$(readlink -f "$1")
			[ -z "$basenameset" ] && basename=$(basename "$dest")
			shift
			continue
		;;
		'-i'|'--window-id')
			shift
			windowopt="-id"
			window="$1"
			shift
			continue
		;;
		'-w'|'--window-name')
			shift
			windowopt="-name"
			window="$1"
			shift
			continue
		;;
		'--')
			shift
			break
		;;
		*)
			echo 'Internal error!' >&2
			exit 1
		;;
	esac
done
if [ -n "$printhelp" ]; then
	usage
	exit 1
fi

prefix="$prefix$basename"

(
	cd "$dest" || (echo 'Could not change directory to '"$dest" && exit 1)
	last=$(ls | egrep '[0-9]+\.(xwd|png)$' | sed -e 's#^.*-\([0-9]\+\)\.\(xwd\|png\)$#\1#' | sort -n | tail -1)
	test -z "$last" && last=0
	next=$(expr $last + 1)
	next=$(printf '%2.2d' "$next")
	dumpname="$prefix-$next.xwd"
	outputname="$prefix-$next.png"
	if [ -z "$window" ]; then
		xwd -root -out "$dumpname" && convert "$dumpname" "$outputname" && rm -f "$dumpname"
	else
		xwd $windowopt "$window" -out "$dumpname" && convert "$dumpname" "$outputname" && rm -f "$dumpname"
	fi
)
