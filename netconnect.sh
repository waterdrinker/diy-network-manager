#!/bin/bash

ethernet="enp8s0"
wlan="wlp6s0"
configpath="/home/pkkf/.wpa"

function CheckSudo(){
	if [ "$HOME" != "/root" ]; then 	
		echo "error: you cannot perform this operation unless you are root."
		exit 1
	fi
}

function CheckDhclient(){
	ps -eo pid,cmd | 
		grep dhclient |
			grep -v grep |
				awk '{print $1}' |
					while read processid
					do
						kill -9 $processid
					done
}

function DisConnect(){
	CheckDhclient
	ip link set $ethernet down
	ip link set $wlan down
}

function EtherConnect(){
	ip link set $ethernet up
	sleep 2
	dhclient $ethernet
}
	
function IwConnect(){
	ip link set $wlan up
	count=0
	stat=$(iw dev $wlan link | sed -n '1p' | awk '{print $1}')
	while [ "$stat" != "Connected" ]; do
		if test count -gt 5; then
			echo "error: wifi connection is failure."
			exit 1
		fi
		count=$((count+1))
		case $1 in
		nju)
			iw dev $wlan connect NJU-WLAN
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
		stat=$(iw dev $wlan link | sed -n '1p' | awk '{print $1}')
	done
	dhclient $wlan
}	

CheckSudo
DisConnect
if [ $# -eq 0 ]; then
	EtherConnect
else
	IwConnect $1 $2
fi

