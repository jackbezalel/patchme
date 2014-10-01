#!/bin/sh

#Functions

function GET_LINUX_VENDOR(){

# centos and oracle must be checked first since sometimes
# the redhat-release file could co-exist along with the centos-release
# or with the oracle-release file

if [ -f /etc/centos-release ];
then
	echo "centos"
	return $TRUE
fi

if [ -f /etc/oracle-release ];
then
	echo "oracle"
	return $TRUE
fi

# centos and oracle must be checked first since sometimes
# the redhat-release file could co-exist along with the centos-release
# or with the oracle-release file

if [ -f /etc/redhat-release ];
then
	echo "redhat"
	return $TRUE
fi

if [ -f /etc/SuSE-release ];
then
	echo "suse"
	return $TRUE
fi

if [ -f /etc/os-release ];
then
	OSDEBIAN=`cat /etc/os-release | head -1 | awk -F\" '{ print $2 }' | awk '{ print $1 }' | cut -b-6`
	OSUBUNTU=`cat /etc/os-release | head -1 | awk -F\" '{ print $2 }' | awk '{ print $1 }' | cut -b-6`
	if [ " $OSDEBIAN" = " Debian" ];
	then
		echo "debian"
		return $TRUE
	fi

	if [ " $OSUBUNTU" = " Ubuntu" ];
	then
		echo "ubuntu"
		return $TRUE
	else
	
		echo "error"
		return $FALSE
	fi
fi


echo "error"
return $FALSE

}

function GET_OS_MAJOR_VERS(){

local OS_VENDOR=$1

if [ "$OS_VENDOR" = "redhat" ];
then
	OS_MAJOR_VERS="`cat /etc/redhat-release | head -1 | awk '{ print $7 }' | awk -F. '{ print $1 }'`"
	echo $OS_MAJOR_VERS
	return $TRUE
fi

echo "error"
return $FALSE

}

#Main

VULN=$1
HOSTNAME=`hostname`
OSNAME=`uname -s`
PATCH_DATE=`date +"%Y%m%d%H%M"`
OSARCH="`uname -i`"

if [ " $VULN" = " " ];
then
	echo "Usage: $0 VulnerabilityID"
	exit
fi


case "$OSNAME" in Linux)
	LINUX_VENDOR="`GET_LINUX_VENDOR`"
	if [ LINUX_VENDOR != " " ];
	then
		echo "Vendor=$LINUX_VENDOR"
		OS_MAJOR_VERS="`GET_OS_MAJOR_VERS $LINUX_VENDOR`"
		echo "Major Version=$OS_MAJOR_VERS"
		MACHINE_PATCH_DIR="/patches/machines/`hostname`/$VULN/$PATCH_DATE"
		VULN_PATCH="/patches/vuln/$VULN/$LINUX_VENDOR/$OS_MAJOR_VERS/$OSARCH"
		mkdir -p $MACHINE_PATCH_DIR
		echo "Machine $HOSTNAME will be patched at $MACHINE_PATCH_DIR by patch at $VULN_PATCH"
		echo "Gathering current (pre-patching) YUM and RPM system info"
		rpm -qa &> $MACHINE_PATCH_DIR/software-pre.txt
		echo "Dry run (verification only) now..."
		rpm -Uvh --test $VULN_PATCH/*.rpm &> $MACHINE_PATCH_DIR/patch-dry.log
		PATCH_STATUS=$?
		if [ $PATCH_STATUS != 0 ];
		then
			touch $MACHINE_PATCH_DIR/patch-dry-bad
			echo "Failed at Dry Run - exiting!"
			exit $FALSE
		else
			touch $MACHINE_PATCH_DIR/patch-dry-ok
		fi
		
		echo "Live update running now..."
		rpm -Uvh $VULN_PATCH/*.rpm &> $MACHINE_PATCH_DIR/patch-live.log
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
	fi
;;
*)
	echo "Error in OS vendor"
	exit
;;
esac

