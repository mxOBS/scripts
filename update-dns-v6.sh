#!/bin/bash -e

# static settings
host=HOST
key=KEY
statedir=~/.update-dns-v6

# load state
if [ ! -d "$statedir" ]; then
	mkdir -vp "$statedir"
fi
last_ipv6=
if [ -r "$statedir/last_v6" ]; then
	last_ipv6=`cat "$statedir/last_v6"`
fi

# figure out public IPs
ipv6=`curl -k http://ip6.ddnss.de/ip.php | xml2 | sed 's/.*=//'`

printf "Detected IPv6=%s (%s)\n" "$ipv6" "$last_ipv6"

# update v6 if changed
if [ "x$last_ipv6" != "x$ipv6" ]; then
echo "Updating IPv6"
	printf -v url "https://dynv6.com/api/update?token=%s&hostname=%s&ipv6=%s" "$key" "$host" "$ipv6"
	curl -k "$url"

	# update state
	echo "$ipv6" > "$statedir/last_v6"
fi
