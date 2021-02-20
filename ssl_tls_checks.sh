#!/bin/bash

function run_sslscan() {
	echo ">> Starting sslscan Checks"

	while read -r line
	do
		min_len=68
        blank_res=580
		echo $sslscan_dir
		output_path="$sslscan_dir/${line}_sslscan.txt"
		echo $output_path
		echo "> Scanning: ${line}"
		/usr/bin/sslscan --no-color $line > $output_path 2>/dev/null
		output_length=`/usr/bin/cat ${output_path} | /usr/bin/wc -m`
		if [ $output_length -eq $min_len ] || [ $output_length -lt $min_len ]
		then
			echo "[!] No connection: ${line}"
			/usr/bin/rm $output_path
        elif [ $output_length -lt $blank_res ]
		then
            echo "> Probable clean result. Check manually: ${line}"
            echo $line >> $sslscan_dir/double_check_with_testssl_sh.txt
		else
			echo "> Report saved for: ${line}"
            echo $line >> $sslscan_dir/.temp.txt
		fi
		echo
	done < $hosts
}


function run_testssl_sh() {
	echo ">> Starting testssl.sh Checks"
	while read -r line
	do
		min_len=68
		output_path="./$testssl_dir/${line}_testssl_sh.txt"
		echo "> Scanning: ${line}"
		/bin/bash $home/repos/testssl.sh/testssl.sh $line > $output_path 2>/dev/null
	done < $sslscan_dir/.temp.txt
}

function check_arguments() {
    if [ -z $projectname ] || [ -f "$projectname" ]
	then 
		echo
        echo "[!] Project name is required as first argument."
        show_help
        exit 1
    fi

    if [ -z "$hosts" ] || [ ! -f "$hosts" ]
	then 
		echo
        echo "[!] Input file required as second argument."
        show_help
        exit 1
    fi
}

function show_help() {
	echo
    echo "> USAGE: bash sslchecks.sh project_name /path/to/hosts.txt"
	echo
}

projectname=$1
hosts=$2
check_arguments
home=/home/$(whoami)
projects_dir=/Dropbox/pcu/projects
base_dir=$home/$projects_dir/$projectname/
sslscan_dir=ssl_enumeration/sslscan_output
testssl_dir=ssl_enumeration/testssl_sh

# Clean up old directories
if [ -d "$sslscan_dir" ]; then /usr/bin/rm -rf $sslscan_dir ; fi
if [ -d "$testssl_dir" ]; then /usr/bin/rm -rf $testssl_dir ; fi

# Create fresh
/usr/bin/mkdir -p $sslscan_dir
/usr/bin/mkdir $testssl_dir

run_sslscan
run_testssl_sh
