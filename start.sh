#!/bin/sh
set -o errexit
set -o pipefail

if [ "$1" != "" ]; then
	sock="/s$1"
else
	numsocks=$(find /s -type s | wc -l)
	if [ $numsocks -gt 1 ]; then
		echo 'Found more than one socket, please pass $SSH_AUTH_SOCK as an image argument'
		exit 1
	elif [ $numsocks -lt 1 ]; then
		echo "Didn't find any sockets, did you volume mount the right directory?"
		exit 1
	fi
	sock=$(find /s -type s)
fi

# `-t` is needed because of https://github.com/docker/docker/issues/16602
socat -t 100000000 TCP-LISTEN:5522,reuseaddr,fork UNIX:$sock
