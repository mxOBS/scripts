#!/bin/bash

if [ "x$#" != "x5" ]; then
	echo "Usage: $0 <local folder> <destination folder> <server> <username> <password>"
	exit 1
fi

SOURCEDIR="$1"
DESTDIR="$2"
SRV="$3"
USER="$4"
PASS="$5"

LOCK=/opt/sync-in-progress

which lftp 2> /dev/null 1>/dev/null
if [ "x$?" != "x0" ]; then
	echo Error: lftp not insttaled!
	exit 1
fi

# lock this script to make sure it wont be run in parallel
t=0
mkdir $LOCK || t=$?
if [ "x$t" != "x0" ]; then
	echo "Error: an instance is already running or terminated undefined"
	exit 1
fi

t=0
lftp -u "$USER","$PASS" "$SRV" << EOF
#mirror --reverse --delete --delete-first --no-perms "$SOURCEDIR" "$DESTDIR"
mirror --reverse --delete -x .htaccess "$SOURCEDIR" "$DESTDIR"
EOF

rmdir $LOCK

exit $t
