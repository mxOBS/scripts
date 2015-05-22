#!/bin/bash

usage() {
	echo "Usage: $0 <primary.xml> <mirror> <destdir>"
}

strip_xml() {
	while read line; do

		# remove first part
		pkg=`echo $line | sed -e 's;^**<location href=\";;g'`

		# remove last part
		pkg=`echo $pkg | sed -e 's;\"/>.*;;g'`

		echo $pkg
	done
}

prepend_mirror() {
	while read line; do
		echo "$mirror/$line"
	done
}

download() {
	while read url; do
		name=`basename $url`
		printf "%s: " $name

		if [ -e "$destdir/$name" ]; then
			# TODO: check if md5 matches

			# skip this package
			status="Skipped"
		else
			# download
			curl -k -o "$destdir/$name" "$url" 1>/dev/null 2>/dev/null
			if [ $? == 0 ]; then
				status="Done"
			else
				status="Failed"
			fi
		fi

		printf "%s\n" $status
	done
}

if [ "x$#" != "x3" ]; then
	usage
	exit 0
fi
metadata="$1"
mirror="$2"
destdir="$3"

grep "<location href=" "$metadata" | strip_xml | prepend_mirror | download
