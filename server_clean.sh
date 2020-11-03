#!/bin/bash
Usage(){
	echo "Usage:"
	echo "./honeypot_clean.sh [-s <string>]"
	echo "Details:"
	echo "-s <string>  —— Need to specify tmux-session-name for server(existed)"
    echo "-c —— clean date_report from server"
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

while getopts ':s:c' OPT; do
	case $OPT in
		s) sname=${OPTARG}
			inList $sname
			[ $? -eq 1 ] || Usage
			;;
        c)
			rm ./localserver/old_data_*.json
			;;
		*)  Usage
	esac
done	
shift $((OPTIND-1))
if [ -z "${sname}" ]; then
       Usage
fi       

echo "Save record_data from server"
tmux send-keys -t$sname C-c C-m    #record data.json
mv /root/honeypot_files/localserver/data.json /root/honeypot_files/localserver/old_data_`date "+%Y%m%d_%H%M%S"`.json
echo "Detele tmux sessiones......."
sleep 2
tmux kill-session -t $sname
