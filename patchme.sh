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
	ls -1 $MACHINE_PATCH_WORK_DIR/patches > $MACHINE_PATCH_WORK_DIR/patchlist

	mkdir -p $MACHINE_PATCH_DIR

	echo "Gathering current (pre-patching) system info"

	if      [ $OS_MAJOR_VERS != "5.11" ]
	then	
		echo "\n\n\n*** pkginfo -l ***\n\n\n" \
			>$MACHINE_PATCH_DIR/software-pre.txt
		pkginfo -l >>$MACHINE_PATCH_DIR/software-pre.txt 2>&1
		echo "\n\n\n*** showrev -p ***\n\n\n" \
			>>$MACHINE_PATCH_DIR/software-pre.txt
		showrev -p >>$MACHINE_PATCH_DIR/software-pre.txt 2>&1
	else
		echo "\n\n\n*** pkg info ***\n\n\n" \
			>$MACHINE_PATCH_DIR/software-pre.txt
		pkg info >>$MACHINE_PATCH_DIR/software-pre.txt 2>&1
	fi

	if 	[ $OS_MAJOR_VERS = "5.10" ] || [ $OS_MAJOR_VERS = "5.11" ];
	then
		echo "Dry run (verification only) now..."

		if      [ $OS_MAJOR_VERS = "5.10" ]
		then
			patchadd -a -M $MACHINE_PATCH_WORK_DIR/patches/ \
				>$MACHINE_PATCH_WORK_DIR/patch-dry.log 2>&1
			PATCH_STATUS=$?
		else	
			# Solaris 5.11... #	
			#pkg update -nv -g $MACHINE_PATCH_WORK_DIR/patches/* \
				>$MACHINE_PATCH_WORK_DIR/patch-dry.log 2>&1
			PATCH_STATUS=$?
		fi

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
	if      [ $OS_MAJOR_VERS != "5.11" ]
	then
		# Any Solaris except for Solaris 11 #
		patchadd -M $MACHINE_PATCH_WORK_DIR/patches \
			`cat $MACHINE_PATCH_WORK_DIR/patchlist` \
			>$MACHINE_PATCH_WORK_DIR/patch-live.log 2>&1
		PATCH_STATUS=$?
	else
		# Solaris 11 taken care here #
		# Next 3 lines are disabled since due to bug in Solaris 11
		# Zones they do not work. Instead I am setting a file
		# based package in the repository for each patch file
		# Once this bug is resolved forward as well as backwards
		# We could consider enabling those 3 lines
		# As to the dry run I am using the original same 3 lines
		# Assuming they do work for dry run
		#pkg update -v -g $MACHINE_PATCH_WORK_DIR/patches/* \
		#	>$MACHINE_PATCH_WORK_DIR/patch-dry.log 2>&1
		#PATCH_STATUS=$?
		NO_SOL11_PATCHES_APPLIED="TRUE"
		for PATCH_FILE in `cat $MACHINE_PATCH_WORK_DIR/patchlist`
		do
			PATCH_NAME=`echo $PATCH_FILE|awk -F. '{ print $1 }'`
			echo "Installing " $PATCH_NAME " ..."
			pkg set-publisher -g \
			   file://$MACHINE_PATCH_WORK_DIR/patches/$PATCH_FILE \
				solaris \
				>>$MACHINE_PATCH_WORK_DIR/patch-live.log 2>&1
			PATCH_STATUS=$?
                	if [ $PATCH_STATUS != $TRUE ];
                	then
                        	touch $MACHINE_PATCH_DIR/patch-live-bad
                        	echo "Failed at Live Run add origin,exiting!"
				cp $MACHINE_PATCH_WORK_DIR/patch-live*.log \
					$MACHINE_PATCH_DIR
                        	exit $FALSE	
			fi
			pkg install $PATCH_NAME \
				>$MACHINE_PATCH_WORK_DIR/patch-live-$PATCH_NAME.log 2>&1
			PATCH_STATUS=$?
                        if [ $PATCH_STATUS != $TRUE ];
                        then
				PATCH_NOT_RELEVANT="`cat $MACHINE_PATCH_WORK_DIR/patch-live-$PATCH_NAME.log | grep 'The installed package ' | grep 'is not permissible.'`"
				PATCH_CANT_BE_APPLIED="`cat $MACHINE_PATCH_WORK_DIR/patch-live-$PATCH_NAME.log | grep 'pkg install: No solution was found to satisfy constraints'`"
				if [ " $PATCH_NOT_RELEVANT" != " " ] || [ " $PATCH_CANT_BE_APPLIED" != " " ];
				then
				echo "Skipping patch $PATCH_NAME, as it is not relevant or can't be applied"
				else
					cat $MACHINE_PATCH_WORK_DIR/patch-live-$PATCH_NAME.log \
						>> $MACHINE_PATCH_WORK_DIR/patch-live.log
                                	touch $MACHINE_PATCH_DIR/patch-live-bad
                                	echo "Failed at Live Run installation,exiting!"

					pkg set-publisher -G \
                           		file://$MACHINE_PATCH_WORK_DIR/patches/$PATCH_FILE \
                                	solaris \
                                	>>$MACHINE_PATCH_WORK_DIR/patch-live.log 2>&1

                                	cp $MACHINE_PATCH_WORK_DIR/patch-live*.log \
                                        	$MACHINE_PATCH_DIR
                                	exit $FALSE
				fi
			else
				NO_SOL11_PATCHES_APPLIED="FALSE"
                        fi

			cat $MACHINE_PATCH_WORK_DIR/patch-live-$PATCH_NAME.log \
				>> $MACHINE_PATCH_WORK_DIR/patch-live.log

			pkg set-publisher -G \
			   file://$MACHINE_PATCH_WORK_DIR/patches/$PATCH_FILE \
				solaris \
				>>$MACHINE_PATCH_WORK_DIR/patch-live.log 2>&1
			PATCH_STATUS=$?
                        if [ $PATCH_STATUS != $TRUE ];
                        then
                                touch $MACHINE_PATCH_DIR/patch-live-bad
                                echo "Failed at Live Run remove origin, exiting!"
                                cp $MACHINE_PATCH_WORK_DIR/patch-live*.log \
                                        $MACHINE_PATCH_DIR
                                exit $FALSE
                        fi
			echo "Finished Installing " $PATCH_NAME " ..."
		done
	fi

	cp $MACHINE_PATCH_WORK_DIR/patch-live*.log $MACHINE_PATCH_DIR

	if 	[ $NO_SOL11_PATCHES_APPLIED = "TRUE" ];
	then
		echo "Warning - No patches applied at all - considering Live Run as Bad. Please check the logs"
	fi

	if [ $PATCH_STATUS != 0 ] || [ $NO_SOL11_PATCHES_APPLIED = "TRUE" ];
	then
		touch $MACHINE_PATCH_DIR/patch-live-bad
		echo "Failed at Live Run - exiting!"
		exit $FALSE
	else
		touch $MACHINE_PATCH_DIR/patch-live-ok
		echo "Live run DONE OK!"
		echo "Generating Post-Patch software list..."

        	if      [ $OS_MAJOR_VERS != "5.11" ]
        	then
                	echo "\n\n\n*** pkginfo -l ***\n\n\n" \
                       	 >$MACHINE_PATCH_DIR/software-post.txt
                	pkginfo -l >>$MACHINE_PATCH_DIR/software-post.txt 2>&1
                	echo "\n\n\n*** showrev -p ***\n\n\n" \
                        	>>$MACHINE_PATCH_DIR/software-post.txt
                	showrev -p >>$MACHINE_PATCH_DIR/software-post.txt 2>&1
        	else
                	echo "\n\n\n*** pkg info ***\n\n\n" \
                        	>$MACHINE_PATCH_DIR/software-post.txt
                	pkg info >>$MACHINE_PATCH_DIR/software-post.txt 2>&1
        	fi

		echo "Done, all OK! Thanks for using the Patcherrrrr!"
		exit $TRUE
	fi
;;
*)
	echo "We do not support patching for $OSNAME yet.."
	exit $TRUE
;;
esac

