#!/bin/bash
Usage(){
	echo "Usage:"
	echo "./honeypot_clean.sh [-h <string>] [-c]"
	echo "Details:"
	echo "-h <string>  —— Need to specify tmux-session-name for honeypot(existed)"
	echo "-c —— clean logs with \"inotifylog_\" prefix"
	exit 1
}

inList(){
	nows=`tmux ls | awk -F:  '{print $1}'`
	for name in ${nows[@]}
	do
		if [ $name == $1 ];then
			return 1
		fi
	done
	return 0
}

while getopts ':h:c' OPT; do
	case $OPT in
		h)	hname=${OPTARG}
			inList $hname
			[ $? -eq 1 ] || Usage
			;;
		c)
			rm ./honeypot_log/inotifylog_*
			;;
		*)  Usage
	esac
done	
shift $((OPTIND-1))
if [ -z "${hname}" ]  ; then
       Usage
fi       

echo "Delete honeypot......"
tmux kill-session -t $hname
crontab -r

echo "Delete tap for network......"
sudo ip link set dev tap111 down
sudo ip tuntap del mode tap dev tap111
#sudo ip link delete tap111


