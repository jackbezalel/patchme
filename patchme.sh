#!/bin/sh

# Author: Jack Bezalel

#Functions

FALSE=1
TRUE=0

. ./get_linux_vendor.sh
. ./get_os_major_vers.sh

#Main

VULN="$1"
HOSTNAME="`hostname`"
OSNAME="`uname -s`"
PATCH_DATE="`date +"%Y%m%d%H%M"`"
OSARCH="`uname -i`"

if [ " $VULN" = " " ];
then
	echo "Usage: $0 VulnerabilityID"
	exit $FALSE
fi

if [ -d "/patches/machines/$HOSTNAME/$VULN" ];
then    
	MACHINE_PATCHED="`find /patches/machines/$HOSTNAME/$VULN/*/patch-live-ok`"
	if [ " $MACHINE_PATCHED" != " " ];
	then
		echo "Machine already marked as patched for $VULN"
		echo "Exiting...!"
		exit $TRUE
	fi
fi


case $OSNAME in
Linux)
	LINUX_VENDOR="`GET_LINUX_VENDOR`"
	if 	[ $LINUX_VENDOR = "error" ];
	then
        	echo "We do not support patching for $OSNAME"
        	exit $FALSE
	fi
	
	echo "Vendor=$LINUX_VENDOR"

	OS_MAJOR_VERS="`GET_OS_MAJOR_VERS $LINUX_VENDOR`"

	if 	[ $OS_MAJOR_VERS = "error" ];
	then
        	echo "We do not support patching for $LINUX_VENDOR"
        	exit $FALSE
	fi
	
	echo "Major Version=$OS_MAJOR_VERS"
	MACHINE_PATCH_DIR="/patches/machines/$HOSTNAME/$VULN/$PATCH_DATE"
	VULN_PATCH="/patches/vuln/$VULN/$LINUX_VENDOR/$OS_MAJOR_VERS/$OSARCH"
	echo "Machine $HOSTNAME will be patched at $MACHINE_PATCH_DIR by patch at $VULN_PATCH"

	if [ $LINUX_VENDOR = "redhat" ];
	then
		mkdir -p $MACHINE_PATCH_DIR
		echo "Gathering current (pre-patching) YUM and RPM system info"
		rpm -qa &> $MACHINE_PATCH_DIR/software-pre.txt
		echo "Dry run (verification only) now..."
		rpm -Fvh --test $VULN_PATCH/*.rpm &> $MACHINE_PATCH_DIR/patch-dry.log
		PATCH_STATUS=$?

		if [ $PATCH_STATUS != $TRUE ];
		then
			touch $MACHINE_PATCH_DIR/patch-dry-bad
			echo "Failed at Dry Run - exiting!"
			exit $FALSE
		else
			touch $MACHINE_PATCH_DIR/patch-dry-ok
		fi
		
		echo "Live update running now..."
		rpm -Fvh $VULN_PATCH/*.rpm &> $MACHINE_PATCH_DIR/patch-live.log
		PATCH_STATUS=$?

		if [ $PATCH_STATUS != 0 ];
		then
			touch $MACHINE_PATCH_DIR/patch-live-bad
			echo "Failed at Live Run - exiting!"
			exit $FALSE
		else
			touch $MACHINE_PATCH_DIR/patch-live-ok
			echo "Live run DONE OK!"
			echo "Generating Post-Patch software list..."
			rpm -qa &> $MACHINE_PATCH_DIR/software-post.txt
			echo "Done, all OK! Thanks for using the Patcherrrrr!"
		fi
	else
		echo "We do not support patching for $LINUX_VENDOR"
		exit $FALSE
	fi
;;
*)
	echo "We do not support patching for $OSNAME"
	exit $FALSE
;;
esac

