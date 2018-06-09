#!/bin/bash

#
# Implementation
#

# out: $SNAPSHOT
snapshot() {
	local DB TIMESTAMP s

	DB=api_production

	# first lock MySQL
	mysql -u root -popensuse $DB -e "FLUSH TABLES WITH READ LOCK;"
	if [ $? -ne 0 ]; then
		echo "Failed to lock Database, aborting!"
		return 2
	fi

	# create snapshot
	TIMESTAMP=`date +%Y-%m-%d-%H:%M`
	btrfs subvolume snapshot -r "${SOURCE}." "${SOURCE}${SNAPSHOTS}${TIMESTAMP}"
	if [ $? -ne 0 ]; then
		echo "Failed to create snapshot!"
		s=3
	fi

	# unlock MySQL
	mysql -u root -popensuse $DB -e "UNLOCK TABLES;"
	if [ $? -ne 0 ]; then
		echo "Failed to unlock Database!"
		s=1
	fi

	# force btrfs flush
	sync

	SNAPSHOT="${TIMESTAMP}"
	return $s
}

# out: $TRANSFERCMD
transfercmd() {
	local MODE OLD NEW

	if [ $# -eq 2 ]; then
		# initial transfer
		NEW="$2"

		printf -v SENDCMD 'btrfs send "%s"' "${SOURCE}${SNAPSHOTS}${NEW}"
		printf -v RECVCMD 'btrfs receive "%s"' "${DESTINATION}${SNAPSHOTS}"
	elif [ $# -eq 3 ]; then
		# differential transfer
		OLD="$2"
		NEW="$3"

		printf -v SENDCMD 'btrfs send -p "%s" "%s"' "${SOURCE}${SNAPSHOTS}${OLD}" "${SOURCE}${SNAPSHOTS}${NEW}"
		printf -v RECVCMD 'btrfs receive "%s"' "${DESTINATION}${SNAPSHOTS}"
	else
		echo "Usage: $0 <push|pull> [<old snapshot>] <new snapshot>"
		exit 1
	fi

	MODE=$1
	case $MODE in
		pull)
			printf -v TRANSFERCMD "ssh %s '%s' | pv | %s" "${SSHOPTIONS}" "${SENDCMD}" "${RECVCMD}"
			return 0
			;;
		push)
			printf -v TRANSFERCMD "%s | pv | ssh %s '%s'" "${SENDCMD}" "${SSHOPTIONS}" "${RECVCMD}"
			return 0
			;;
		*)
			echo "Invalid mode specified, aborting!"
			return 1
			;;
	esac
}

# out: $OLD, $NEW
getlatestsnapshots() {
	OLD=
	NEW=

	LIST=`ls "${SOURCE}${SNAPSHOTS}" | sort | tail -2`
	for token in $LIST; do
		OLD="$NEW"
		NEW="$token"
	done
}

#
# Configuration
#

# location of source volume
SOURCE=/srv/obs/

# location of snapshots relative to source (destination) volume
SNAPSHOTS=snapshots/

# location of destination volume
DESTINATION=/media/obs-data/

# ssh cmdline options (e.g. hostname, port, password, ...)
SSHOPTIONS="-p 3022 root@192.168.0.146"

# mode of operation (pull/push)
MODE=pull

#
# Execution
#

# first create a snapshot
snapshot
if [ $? -ne 0 ]; then
	# too bad
	exit 1
fi

# find snapshots
getlatestsnapshots

# generate transfer command
transfercmd $MODE $OLD $NEW

echo "Use this command to transmit:"
echo $TRANSFERCMD
