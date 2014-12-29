#!/bin/sh

# Author: Jack Bezalel
# General Service Functions


EXIT_IF_ERR()
{

EXIT_STATUS=$1
EXIT_STAGE=$2

if [ $EXIT_STATUS != $TRUE ];
then
	echo "Fatal Error - Exiting"
	touch "$EXIT_STAGE"
	exit
else
	return $TRUE
fi

}

