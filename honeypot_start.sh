#!/bin/bash
# running by root
Usage(){
        echo "Usage:"
        echo "./honeypot_start.sh [-h <string>] [-f <int>]"
        echo "Details:"
		echo "-h <string>  —— Specify the tmux-session name of honeypot(not duplicate)"
        echo "-f <int>  —— Specify a port for port-forwarding"
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

while getopts ':h:f:' OPT; do
        case $OPT in
                h) hname=${OPTARG}
                   inList $hname
                   if [ $? -eq 1 ]; then
                        Usage
                   fi  
                ;;
                f) fport=${OPTARG}
                ;;
                *) Usage
        esac
done
shift $((OPTIND-1))
if [ -z "${hname}" ] || [ -z "${fport}" ]; then
	Usage
fi

if [ type tmux >/dev/null 2>&1 ];then
	sudo apt-get install tmux
fi
echo "Create a tap whose ip is 192.168.1.101/24"
sudo ip tuntap add mode tap tap111
sudo ip link set dev tap111 up
sudo ip addr add 192.168.1.101/24 dev tap111

echo "Create honeypot......."
tmux new-session -d -s $hname
if [ $? -eq 1 ]; then
	echo "Error: Change your tmux-session-name"
	exit
fi
fprefix="/root/honeypot_files/new_firmware/"
#tmux send-keys 'sudo qemu-system-aarch64 \
#        -m 1024 -smp 2 -cpu cortex-a57 -M virt -nographic \
#        -kernel '$fprefix'lede-armvirt-zImage-initramfs \
#        -drive if=none,file='$fprefix'lede-armvirt-zImage-initramfs,format=raw,id=hd0 \
#        -device virtio-blk-device,drive=hd0 \
#        -device virtio-net-pci,netdev=lan \
#        -netdev tap,id=lan,ifname=tap111,script=no,downscript=no \
#        -device virtio-net-pci,netdev=wan \
#        -netdev user,id=wan,hostfwd=tcp::'$fport'-:22' C-m

tmux send-keys -t$hname 'qemu-system-arm -m 1024 -smp 2 -cpu cortex-a15 \
        -M virt -nographic -kernel '$fprefix'lede-armvirt-zImage-initramfs \
        -drive if=none,file='$fprefix'lede-armvirt-zImage-initramfs,format=raw,id=hd0\
         -device virtio-blk-device,drive=hd0 -device virtio-net-pci,netdev=lan \
         -netdev tap,id=lan,ifname=tap111,script=no,downscript=no \
         -device virtio-net-pci,netdev=wan -netdev user,id=wan,hostfwd=tcp::'$fport'-:22' C-m


echo "Using [port"$fport"] to accomplish port forwarding......"
# tmux send-keys $pw C-m 
#C-m means hit return. C- means Ctrl,M- means Alt.Detials in https://stackoverflow.com/questions/19313807/tmux-send-keys-syntax
#tmux detach -s $3

echo "Need 100 second for activating interface"
sleep 100
tmux send-keys -t$hname Enter Enter
echo "Done~"
