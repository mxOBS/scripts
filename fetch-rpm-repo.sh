#!/bin/bash

usage() {
	echo "Usage: $0 <primary.xml> <mirror> <destdir>"
}

read_file() {
	uri="$1"
	if [[ $uri = http://* ]]; then
		cmd="curl -k $uri 2>/dev/null"
	else
		cmd="cat $uri"
	fi

	# unpackif necessary
	if [[ $uri = *.gz ]]; then
		eval $cmd | gzip -d
	else
		eval $cmd
	fi
}

extract_data() {
	name=
	chksum=
	chksumtype=
	location=
	while read line; do
		if [[ $line = \<package\ * ]]; then
			name=
			chksum=
			chksumtype=
			location=
		fi
		if [[ $line = \<name* ]]; then
			name=$(echo $line | sed -e "s;<name>;;g" -e "s;</name>;;g")

			continue
		fi
		if [[ $line = \<checksum*sha256* ]]; then
			chksum=$(echo $line | sed -e 's;<checksum type="sha256" pkgid="YES">;;g' -e "s;</checksum>;;g")
			chksumtype=sha256

			continue
		fi
		if [[ $line = \<location* ]]; then
			location=$(echo $line | sed -e "s;<location href=;;g" -e "s;/>;;g" -e 's;";;g')

			continue
		fi
		if [[ $line = \</package\> ]]; then
			echo $name $mirror/$location $chksumtype $chksum

			continue
		fi
	done
}

download() {
	while read line; do
		name=$(echo $line | cut -d' ' -f1)
		location=$(echo $line | cut -d' ' -f2)
		chksumtype=$(echo $line | cut -d' ' -f3)
		chksum=$(echo $line | cut -d' ' -f4)

		filename=`basename $location`
		printf "%s: " $name

		if [ -e "$destdir/$filename" ]; then
			# check if chksum matches
			matches=no
			if [ "$chksumtype" = "sha256" ]; then
				echo "$chksum $destdir/$filename" | sha256sum -c 2>/dev/null 1>/dev/null
				if [ $? = 0 ]; then
					matches=yes
				fi
			fi

			# if checksum matches, keep the file
			if [ "$matches" = "yes" ]; then
				status="Skipped"
			else
				# get rid of the bad file
				rm -f $filename

				# then download
				curl -k -o "$destdir/$filename" "$location" 1>/dev/null 2>/dev/null
				if [ $? == 0 ]; then
					status="Replaced"
				else
					status="Failed"
				fi
			fi
		else
			# download
			curl -k -o "$destdir/$filename" "$location" 1>/dev/null 2>/dev/null
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

#read_file "$metadata" | grep "<location href=" | strip_xml | prepend_mirror | download
read_file "$metadata" | extract_data | download
