#!/bin/sh

# Author: Jack Bezalel

#Functions

# General notes
#
# The following situations NOT considered an error, thus 
# we exit with $TRUE (all OK) in those cases:
# 1. Not supporting an operating system 
# 2. No patch for this operating system
#

FALSE=1
TRUE=0

. ./get_linux_vendor.sh
. ./get_os_major_vers.sh

#Main

VULN="$1"
HOSTNAME="`hostname`"
OSNAME="`uname -s`"
PATCH_DATE="`date +"%Y%m%d%H%M"`"

if [ " $VULN" = " " ];
then
	echo "Usage: $0 VulnerabilityID"
	exit $FALSE
fi

if [ -d "/patches/machines/$HOSTNAME/$VULN" ];
then    
	MACHINE_PATCHED="`find /patches/machines/$HOSTNAME/$VULN/*/patch-live-ok 2>/dev/null`"
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
        	echo "We do not support patching for $OSNAME yet.."
        	exit $TRUE
	fi
	
	echo "Vendor=$LINUX_VENDOR"

	OS_MAJOR_VERS="`GET_OS_MAJOR_VERS $LINUX_VENDOR`"

	if 	[ $OS_MAJOR_VERS = "error" ];
	then
        	echo "We do not support patching for $LINUX_VENDOR yet.."
        	exit $TRUE
	fi
	
	echo "Major Version=$OS_MAJOR_VERS"
	OSARCH="`uname -i`"
	MACHINE_PATCH_DIR="/patches/machines/$HOSTNAME/$VULN/$PATCH_DATE"
	VULN_PATCH="/patches/vuln/$VULN/$LINUX_VENDOR/$OS_MAJOR_VERS/$OSARCH"
	echo "Machine $HOSTNAME will be patched at $MACHINE_PATCH_DIR by patch at $VULN_PATCH"

	if [ $LINUX_VENDOR = "redhat" ];
	then
		mkdir -p $MACHINE_PATCH_DIR
		echo "Gathering current (pre-patching) YUM and RPM system info"
		rpm -qa > $MACHINE_PATCH_DIR/software-pre.txt 2>&1
		echo "Dry run (verification only) now..."
		rpm -Fvh --test $VULN_PATCH/*.rpm > $MACHINE_PATCH_DIR/patch-dry.log 2>&1
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
		rpm -Fvh $VULN_PATCH/*.rpm > $MACHINE_PATCH_DIR/patch-live.log 2>&1
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
			rpm -qa > $MACHINE_PATCH_DIR/software-post.txt 2>&1
			echo "Done, all OK! Thanks for using the Patcherrrrr!"
		fi
	else
		echo "We do not support patching for $LINUX_VENDOR yet.."
		exit $TRUE
	fi
;;
SunOS)
	OS_MAJOR_VERS="`GET_OS_MAJOR_VERS $OSNAME`"

	if 	[ $OS_MAJOR_VERS = "error" ];
	then
        	echo "We do not support patching for $OSNAME yet.."
        	exit $TRUE
	fi

	echo "Vendor=$OSNAME"	
	echo "Major Version=$OS_MAJOR_VERS"
	
	# Check if this machine has zones software installed
	# Then if that's a sparse zone it should be handled by
	# updating the global zone rather than directly

	if	[ -f /usr/bin/zonename ];
	then
		ZONE_NAME="`zonename`"
		echo "ZONE $ZONE_NAME"
		ZONE_TYPE="`pkgcond -n is_what | grep 'is_global_zone=0'`"
		if	[ " $ZONE_TYPE" != " " ];
		then	
			echo "Execution aborted since this NOT a global zone."
			echo "Please re-run on the global zone."
			exit $TRUE
		fi
	fi

	OSARCH="`uname -m`"
	MACHINE_PATCH_DIR="/patches/machines/$HOSTNAME/$VULN/$PATCH_DATE"
	MACHINE_PATCH_WORK_DIR="/tmp/PatchMe/$VULN/$PATCH_DATE"
	VULN_PATCH="/patches/vuln/$VULN/$OSNAME/$OS_MAJOR_VERS/$OSARCH"

	if 	[ ! -d "$VULN_PATCH" ];
	then
		echo "There is no patch for this machine at $VULN_PATCH"
		echo "Exiting..."
		exit $TRUE
	fi

	echo "Machine $HOSTNAME will be patched at $MACHINE_PATCH_DIR"
	echo "by patch from $VULN_PATCH"
	echo "using temporary work directory at $MACHINE_PATCH_WORK_DIR"

	mkdir -p $MACHINE_PATCH_WORK_DIR
	mkdir -p $MACHINE_PATCH_WORK_DIR/patches

	cp -pr $VULN_PATCH/* $MACHINE_PATCH_WORK_DIR/patches
	ls -1 $MACHINE_PATCH_WORK_DIR/patches > $MACHINE_PATCH_WORK_DIR/patches/patchlist

	mkdir -p $MACHINE_PATCH_DIR

	echo "Gathering current (pre-patching) system info"
	echo "*** pkginfo -l ***\n\n\n" >$MACHINE_PATCH_DIR/software-pre.txt
	pkginfo -l >>$MACHINE_PATCH_DIR/software-pre.txt 2>&1
	echo "*** showrev -p ***\n\n\n" >>$MACHINE_PATCH_DIR/software-pre.txt
	showrev -p >>$MACHINE_PATCH_DIR/software-pre.txt 2>&1

	if 	[ $OS_MAJOR_VERS = "5.10" ];
	then
		echo "Dry run (verification only) now..."
		patchadd -a -M $MACHINE_PATCH_WORK_DIR/patches/ \
				>$MACHINE_PATCH_WORK_DIR/patch-dry.log 2>&1
		PATCH_STATUS=$?

		cp $MACHINE_PATCH_WORK_DIR/patch-dry.log $MACHINE_PATCH_DIR

		if [ $PATCH_STATUS != $TRUE ];
		then
			touch $MACHINE_PATCH_DIR/patch-dry-bad
			echo "Failed at Dry Run - exiting!"
			exit $FALSE
		else
			touch $MACHINE_PATCH_DIR/patch-dry-ok
		fi
	else
		echo "Dry run is not available for $OSNAME $OS_MAJOR_VERS"
	fi

	echo "Live update running now..."
	patchadd -M $MACHINE_PATCH_WORK_DIR/patches patchlist \
			>$MACHINE_PATCH_WORK_DIR/patch-live.log 2>&1
	PATCH_STATUS=$?

	cp $MACHINE_PATCH_WORK_DIR/patch-live.log $MACHINE_PATCH_DIR

	if [ $PATCH_STATUS != 0 ];
	then
		touch $MACHINE_PATCH_DIR/patch-live-bad
		echo "Failed at Live Run - exiting!"
		exit $FALSE
	else
		touch $MACHINE_PATCH_DIR/patch-live-ok
		echo "Live run DONE OK!"
		echo "Generating Post-Patch software list..."
		echo "*** pkginfo -l ***\n\n\n" >$MACHINE_PATCH_DIR/software-post.txt
		pkginfo -l >>$MACHINE_PATCH_DIR/software-post.txt 2>&1
		echo "*** showrev -p ***\n\n\n" >>$MACHINE_PATCH_DIR/software-post.txt
		showrev -p >>$MACHINE_PATCH_DIR/software-post.txt 2>&1
		echo "Done, all OK! Thanks for using the Patcherrrrr!"
		exit $TRUE
	fi
;;
*)
	echo "We do not support patching for $OSNAME yet.."
	exit $TRUE
;;
esac

