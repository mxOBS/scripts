#!/bin/bash -e

# static settings
host=HOST
key=KEY
statedir=~/.update-dns

# load state
if [ ! -d "$statedir" ]; then
	mkdir -vp "$statedir"
fi
last_ipv4=
if [ -r "$statedir/last_v4" ]; then
	last_ipv4=`cat "$statedir/last_v4"`
fi
last_ipv6=
if [ -r "$statedir/last_v6" ]; then
	last_ipv6=`cat "$statedir/last_v6"`
fi

# figure out public IPs
ipv4=`curl -k http://ip4.ddnss.de/ip.php | xml2 | sed 's/.*=//'`
ipv6=`curl -k http://ip6.ddnss.de/ip.php | xml2 | sed 's/.*=//'`

printf "Detected IPv4=%s (%s), IPv6=%s (%s)\n" "$ipv4" "$last_ipv4" "$ipv6" "$last_ipv6"

# update v4 if changed
if [ "x$last_ipv4" != "x$ipv4" ]; then
	echo "Updating IPv4"
	printf -v url "https://dynv6.com/api/update?token=%s&hostname=%s&ipv4=%s" "$key" "$host" "$ipv4"
	curl -k "$url"

	# update state
	echo "$ipv4" > "$statedir/last_v4"
fi
# update v6 if changed
if [ "x$last_ipv6" != "x$ipv6" ]; then
echo "Updating IPv6"
	printf -v url "https://dynv6.com/api/update?token=%s&hostname=%s&ipv6=%s" "$key" "$host" "$ipv6"
	curl -k "$url"

	# update state
	echo "$ipv6" > "$statedir/last_v6"
fi
