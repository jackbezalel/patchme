SunOS)
	OS_MAJOR_VERS="`GET_OS_MAJOR_VERS $OSNAME`"

	if 	[ $OS_MAJOR_VERS = "error" ];
	then
        	echo "We do not support patching for $OSNAME"
        	exit $FALSE
	fi

	OS_VENDOR="SunOS"
	echo "Vendor=$OS_VENDOR"	
	echo "Major Version=$OS_MAJOR_VERS"
	
	# Check if this machine has zones software installed
	# Then if that's a sparse zone it should be handled by
	# updating the global zone rather than directly

	if	[ -f /usr/bin/zonename ];
	then
		ZONE_NAME="`zonename`"
		echo "ZONE $ZONE_NAME"
		pkgcond is_sparse_root_nonglobal_zone
		if	[ $? ];
		then	echo "Execution aborted since this is a sparse zone."
			echo "Please re-run on the global zone."
			exit
		fi
	fi

	OSARCH="`uname -m`"
	MACHINE_PATCH_DIR="/patches/machines/$HOSTNAME/$VULN/$PATCH_DATE"
	VULN_PATCH="/patches/vuln/$VULN/$OS_VENDOR/$OS_MAJOR_VERS/$OSARCH"
	echo "Machine $HOSTNAME will be patched at $MACHINE_PATCH_DIR by patch at $VULN_PATCH"

	exit

	mkdir -p $MACHINE_PATCH_DIR
	echo "Gathering current (pre-patching) pkginfo -l system info"
	pkginfo -l &> $MACHINE_PATCH_DIR/software-pre.txt
	echo "Dry run (verification only) now..."
	pkgchk -d $VULN_PATCH &> $MACHINE_PATCH_DIR/patch-dry.log
	PATCH_STATUS=$?

	if [ $PATCH_STATUS != $TRUE ];
	then
		touch $MACHINE_PATCH_DIR/patch-dry-bad
		echo "Failed at Dry Run - exiting!"
		exit $FALSE
	else
		touch $MACHINE_PATCH_DIR/patch-dry-ok
	fi

	exit
		
	echo "Live update running now..."
	pkgadd -d $VULN_PATCH &> $MACHINE_PATCH_DIR/patch-live.log
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
		pkginfo -l &> $MACHINE_PATCH_DIR/software-post.txt
		echo "Done, all OK! Thanks for using the Patcherrrrr!"
	fi
else
	echo "We do not support patching for $LINUX_VENDOR"
	exit $FALSE
fi
;;

