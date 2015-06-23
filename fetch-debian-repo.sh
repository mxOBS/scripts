#!/bin/bash

# arguments
usage() {
	echo "$0 <distro> <release>"
}
if [ $# != 2 ]; then
	usage
	exit 1
fi
DISTRO=$1
RELEASE=$2

# settings
MIRROR=http://ftp.no.debian.org/
#DISTRO=debian
#RELEASE=wheezy
REPO=main
ARCHITECTURE=armhf
DESTDIR="$PWD"

##############################################################################################

# parses packages file and extracts relevant information
function parse_pkgs() {
	infile=$1

	name=
	url=
	chksum=
	while IFS= read line; do
		# look for a keyword, or empty line
		if [[ $line = Package:* ]]; then
			name=`echo $line | sed -e "s;^Package: ;;g"`
			continue
		fi
		if [[ $line = Filename:* ]]; then
			url=`echo $line | sed -e "s;^Filename: ;;g"`
			continue
		fi
		if [[ $line = MD5sum:* ]]; then
			chksum=`echo $line | sed -e "s;^MD5sum: ;;g"`
			continue
		fi
		if [ -z "$line" ]; then
			# end of section
			# check if one package is known
			if [ ! -z "$name" ] && [ ! -z "$url" ] && [ ! -z "$chksum" ]; then
				echo "$MIRROR/$DISTRO/$url $chksum"
			fi
			# clear data
			name=
			url=
			chksum=
			continue
		fi
	done < $infile

}

function download_checked() {
	while IFS= read line; do
		chksum=`echo $line | cut -d' ' -f2`
		url=`echo $line | cut -d' ' -f1`
		filename=`basename $url`
		printf "%s: " "$filename"

		changed=no
		if [ -e "$filename" ]; then
			echo "$chksum $filename" | md5sum -c 2>/dev/null 1>/dev/null
			if [ $? -eq 0 ]; then
				printf "skipped\n"
				continue
			fi
			rm -f $filename
			changed=yes
		fi

		curl -k $url -o $filename 2>/dev/null
		if [ $? -ne 0 ]; then
			printf "failed\n"
			#echo "Failed to download $url!"
		else
			if [ "x$changed" = "xno" ]; then
				printf "done\n"
			else
				printf "updated\n"
			fi
		fi
	done
}

##############################################################################################

mkdir -p $DESTDIR
pushd $DESTDIR

if [ ! -e Release ] || [ ! -e Packages ]; then
	rm -f Release Packages

	# download release file for the record	
	curl -k $MIRROR/$DISTRO/dists/$RELEASE/$REPO/binary-$ARCHITECTURE/Release -o Release

	# download packages list
	curl -k $MIRROR/$DISTRO/dists/$RELEASE/$REPO/binary-$ARCHITECTURE/Packages.bz2 -o Packages.bz2
	bunzip2 Packages.bz2
fi

# parse packages file and download packages
parse_pkgs Packages | download_checked

# done
popd
