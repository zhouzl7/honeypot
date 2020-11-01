#!/bin/bash
Usage(){
	echo "Usage:"
	echo "./honeypot_build.sh [-h <string>]"
	echo "Details:"
	echo "-h <string>  —— Need to specify tmux-session-name for honeypot(existing)"
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
while getopts ':h:' OPT; do
	case $OPT in
		h)	hname=${OPTARG}
			inList $hname
			[ $? -eq 1 ] || Usage
			;;
		*)  Usage
	esac
done	
if [ -z "${hname}" ]; then
	Usage
fi
shift $((OPTIND-1))


dsthost="root@192.168.1.1"
port="-p22"
fprefix="/root/honeypot_files"
fname=("sensitivefname" "inotify")
# ssh-keygen -f "~/.ssh/known_hosts" -R 192.168.1.1

sshpass -p "root" ssh $port $dsthost  "tee -a /etc/dropbear/authorized_keys" < ~/.ssh/id_rsa.pub 

if [ $? -eq 0 ]
then
	echo "Push public key successfully......"
else
	echo "Adding public_key to honeypot failed "
fi

#ssh $port $dsthost "service firewall stop" #if not stop firewall,vps still can connect by lan.But can not ssh by wan
#ssh $port $dsthost "tee -a /etc/config/firewall" < ${fprefix}/honeypot_fwrule
#tmux send-keys -t$hname Enter "service firewall restart" Enter C-m
#if [ $? -eq 0 ];then 
#	echo "config firewall in honeypots......"
#else
#	echo "Stopping firewall of honeypot failed"
#fi	

#tmux send-keys -t$hname Enter "service firewall restart" Enter

#ssh $port $dsthost "passwd" < ${fprefix}/honeypot_pw

echo "Prepare for system-file-modify log........."
for file in ${fname[@]}
do
	scp -P 22 ${fprefix}/$file ${dsthost}:/tmp/
done
ssh $port $dsthost "cd /tmp;mv ./inotify ./ssh1;./ssh1 > /tmp/hoNeyP0t_10gs 2>&1 &"
crontab /root/honeypot_files/mcronfile

#blog.damonkelley.me/2016/09/07/tmux-send-keys/
