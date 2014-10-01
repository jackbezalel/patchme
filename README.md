patchme
=======

Unix/Linux Hot Vulnerability mass patching tool, identifies the operating system and uses a simple repository to patch, log and manage the process

To use patch me you need to have this directory structure in place:

/patches

/patches/bin - includes all .sh project files, this README and LICNESE files

/patches/vuln/VULN/OS/OSMAJOR/ARCH/

	VULN = label you use through out the patch process to identify a vulnerability that needs patching
	OS = label which the get_linux_vendor.sh function provides and labesls for each operating system type, based on information it gathers from the running system (redhat,suse,centos,oracle,debian,ubuntu as well as others that will be added such as fedora,solaris,hpux,aix and more)
	OSMAJOR = major operating system version - Redhat 5, 6 or 7 for example. Patches for a minor verion will still be placed in the OSMAJOR directory
	ARCH = architectures for each operating system, such as i386, x64_86, ia64 and others - based on uname -i output for a machine

/patches/vuln sample Directory structure:
==========================================

/patches/vuln
/patches/vuln/CVE-2014-7169-shellshock
/patches/vuln/CVE-2014-7169-shellshock/redhat
/patches/vuln/CVE-2014-7169-shellshock/redhat/7
/patches/vuln/CVE-2014-7169-shellshock/redhat/7/x86_64
/patches/vuln/CVE-2014-7169-shellshock/redhat/6
/patches/vuln/CVE-2014-7169-shellshock/redhat/6/x86_64
/patches/vuln/CVE-2014-7169-shellshock/redhat/6/i386
/patches/vuln/CVE-2014-7169-shellshock/redhat/5
/patches/vuln/CVE-2014-7169-shellshock/redhat/5/x86_64
/patches/vuln/CVE-2014-7169-shellshock/redhat/5/i386
/patches/vuln/CVE-2014-7169-shellshock/redhat/5/ia64



