#!/bin/sh

# Author: Jack Bezalel
# Functions


GET_LINUX_VENDOR()
{

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

