#!/bin/bash

# sniff auto sur les réseaux open


WIFI_INTERFACE=wlp2s0
# ESSID="foyer etudiant"
ESSID="osiris"


prepare(){
	sudo pkill NetworkManager
	sudo ip link set up dev $WIFI_INTERFACE	
}

get_maxsta(){
	grep "$ESSID" mon_scan -B 3 -A 1|grep '* station count: [1-9]*' -B 4 -o|grep "[1-9]*$" -o|sort -nr|head -n 1
}
get_chan(){
	# utiliser une autre métrique comme le signal pour différentier les autre
	grep "* station count: $HIGH_CLIENT" mon_scan -A 1|grep "primary channel:"|grep "[1-9][0-9]*$" -o|head -n 1
}

scan(){
	echo Scan
	sudo iw dev $WIFI_INTERFACE scan| egrep 'BSS.*\(|SSID:|primary channel:|signal:|station count:'|grep "primary channel:" -B 4 > mon_scan
	HIGH_CLIENT=$(get_maxsta)
	CHANNEL_Target=$(get_chan)
	# rm mon_scan
}

conf(){
	echo changing channel
	sudo iwconfig $WIFI_INTERFACE freq $CHANNEL_Target
	echo changing mode to monitore
	sudo ip link set down $WIFI_INTERFACE
	sudo iwconfig $WIFI_INTERFACE mode monitore
	sudo ip link set up $WIFI_INTERFACE
}

restore(){
	echo restore to managed
	sudo ip link set down $WIFI_INTERFACE
	sudo iwconfig $WIFI_INTERFACE mode managed
	sudo ip link set up $WIFI_INTERFACE
	sudo NetworkManager
}

s_tshark(){
	       # -I|--monitor-mode

# radiotap.vht.bw == 4 => filtre 80MHZ

	# erreur a l'écriture de fichier standar je doit rediriger
	CAPTURE_OUT=$(date +%X)-chan_$CHANNEL_Target.pcapng
	echo capture $CAPTURE_OUT
	sudo tshark -i $WIFI_INTERFACE -w  - > $CAPTURE_OUT
}

interact(){

	sudo wireshark

	# echo 
	# read custom_cmd
	# zsh -c $custom_cmd

	# s_tshark
}

prepare

if [[ $# != 0 ]]; then
	# set une freq
	CHANNEL_Target=$1
elif [[ condition ]]; then
	# modde auto
	scan
	echo $HIGH_CLIENT station connecter au channel $CHANNEL_Target ! 
fi
conf
s_tshark
restore