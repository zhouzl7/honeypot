#!/bin/bash
# running by root
Usage(){
        echo "Usage:"
        echo "./server_start.sh [-s <string>]"
        echo "Details:"
        echo "-s <string>  —— Specify the tmux-session name of report_server(not duplicate)"
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

while getopts 's:' OPT; do
        case $OPT in
                s) sname=${OPTARG}
                   inList $sname
                   if [ $? -eq 1 ]; then
                        Usage
                   fi  
                ;;
                *) Usage
        esac
done
shift $((OPTIND-1))
if [ -z "${sname}" ]; then
	Usage
fi
if [ type tmux >/dev/null 2>&1 ];then
	sudo apt-get install tmux
fi

if [ -n "${sname}" ]; then
        echo "Create a server to report records....."
        rm data.json
        tmux new-session -d -s $sname
        tmux send-keys -t$sname 'cd ./localserver; python3 server.py' C-m
        sleep 5
fi

echo "Done~"
