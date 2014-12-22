#!/bin/bash
#
# Use ip, wpa_supplient, iw to connect Internet, and obtain dynamic IP using dhclient.
# 
# Usage:
#      netconnect [] []
#
#
#
#

ETHERNET="enp8s0"
WLAN="wlp6s0"
WPA_PATH=$HOME/.wpa

error()
{
	echo "$@" 1>&2
	usage_and_exit 1
}

usage()
{
	echo "Usage: $PROGRAM [--help] [--version] [--wpa-path <path>] <command> [<args>]"
	echo ""
	echo "The commands are:"
	echo "  nju         Connect the Nanjing University Campus Wi-Fi without"
	echo "  wpa         Connect wpa"
	echo "  wep         Connect wep"
	echo "  disconnect  Connect wep"
}

usage_and_exit()
{
	usage
	exit $1
}

version()
{
	echo "$PROGRAM version $VERSION"
}

warning()
{
	echo "$@" 1>&2
	EXITCODE=$(($EXITCODE +1))
}


CheckSudo(){
	if [ "$HOME" != "/root" ]; then 	
		echo "error: you cannot perform this operation unless you are root."
		exit 1
	fi
}

CheckDhclient(){
	ps -eo pid,cmd | 
		grep dhclient |
			grep -v grep |
				awk '{print $1}' |
					while read processid
					do
						kill -9 $processid
					done
}

DisConnect(){
	CheckDhclient
	ip link set $ETHERNET down
	ip link set $WLAN down
}

EtherConnect(){
	ip link set $ETHERNET up
	sleep 2
	dhclient $ETHERNET
}
	
function IwConnect(){
	ip link set $WLAN up
	count=0
	stat=$(iw dev $WLAN link | sed -n '1p' | awk '{print $1}')
	while [ "$stat" != "Connected" ]; do
		if test count -ge 5; then
			echo "error: wifi connection is failure."
			exit 1
		fi
		count=$((count+1))
		case $1 in
		nju)
			iw dev $WLAN connect NJU-WLAN
			;;
		wep)
			echo "wep"
			exit 1
			;;
		wpa)
			echo "wpa"
			exit 1
			;;
		*)
			echo "error: unknown option."
			exit 1
			;;
		esac
		sleep 1
		stat=$(iw dev $WLAN link | sed -n '1p' | awk '{print $1}')
	done
	dhclient $WLAN
}	

EXITCODE=0
PROGRAM=$(basename $0)
VERSION=0.1

while test $# -gt 0
do
	case $1 in
		--help|--hel|--he|--h|'--?'|-help|-hel|-he|-h|'-?')
			usage_and_exit 0
			;;
		--version|-v)
			version
			exit 0
			;;
		-*)
			error "Unrecognized option: $1"
			;;
		*)
			break
			;;
	esac
	shift
done

CheckSudo
DisConnect
if [ $# -eq 0 ]; then
	EtherConnect
else
	IwConnect $1 $2
fi

