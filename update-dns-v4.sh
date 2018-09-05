#!/bin/bash -e

# static settings
host=HOST
key=KEY
statedir=~/.update-dns-v4

# load state
if [ ! -d "$statedir" ]; then
	mkdir -vp "$statedir"
fi
last_ipv4=
if [ -r "$statedir/last_v4" ]; then
	last_ipv4=`cat "$statedir/last_v4"`
fi

# figure out public IPs
ipv4=`curl -k http://ip4.ddnss.de/ip.php | xml2 | sed 's/.*=//'`

printf "Detected IPv4=%s (%s)\n" "$ipv4" "$last_ipv4"

# update v4 if changed
if [ "x$last_ipv4" != "x$ipv4" ]; then
	echo "Updating IPv4"
	printf -v url "https://dynv6.com/api/update?token=%s&hostname=%s&ipv4=%s" "$key" "$host" "$ipv4"
	curl -k "$url"

	# update state
	echo "$ipv4" > "$statedir/last_v4"
fi
