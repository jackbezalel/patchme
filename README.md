patchme
=======

Unix/Linux Hot Vulnerability mass patching tool, identifies the operating system and uses a simple repository to patch, log and manage the process

Author: Jack Bezalel ( http://jackbezalel.com http://jackbezalel.net http://linkedin.com/in/jackbezalel )

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

patchme activation:
=====================

cd /patches/bin
./patchme.sh

The patchme.sh script will automatically create the /patches/machines directory for each machine, for any patch it gets applied and for any date/hour/minute the patchme script was activated for this vulnerability

/patches/machines sample directory:


/patches/machines/
/patches/machines/MACHINE
/patches/machines/MACHINE/CVE-2014-7169-shellshock
/patches/machines/MACHINE/CVE-2014-7169-shellshock/201409301817
/patches/machines/MACHINE/CVE-2014-7169-shellshock/201409301817/software-pre.txt
/patches/machines/MACHINE/CVE-2014-7169-shellshock/201409301817/patch-dry.log
/patches/machines/MACHINE/CVE-2014-7169-shellshock/201409301817/patch-dry-ok
/patches/machines/MACHINE/CVE-2014-7169-shellshock/201409301817/patch-live.log
/patches/machines/MACHINE/CVE-2014-7169-shellshock/201409301817/patch-live-ok
/patches/machines/MACHINE/CVE-2014-7169-shellshock/201409301817/software-post.txt
/patches/machines/MACHINE/CVE-2014-7169-shellshock/201410011412
/patches/machines/MACHINE/CVE-2014-7169-shellshock/201410011412/software-pre.txt
/patches/machines/MACHINE/CVE-2014-7169-shellshock/201410011412/patch-dry.log
/patches/machines/MACHINE/CVE-2014-7169-shellshock/201410011412/patch-dry-bad

In this exmaple patchme created 2 instances of its activation.
The first instance logged at:
/patches/machines/MACHINE/CVE-2014-7169-shellshock/201410011412
includes:
software-pre.txt - output of the software packages installed on machine "MACHINE" before the patching
patch-dry.log - log of the "dry run" - verification of patching, before actually committed
patch-dry-bad - status file that gets created if the "dry run" fails - in this case the "Live Update" will not be executed

The 2nd instance of patchme includes:
software-pre.txt - explained already
patch-dry.log - explaned already, and in this instance it was executed fine
patch-dry-ok - status file that gets created if the "Dry Run" succeeds
patch-live.log - log of the "live update" - actual patching that got committed
patch-live-ok - status file which gets created when the "Live Update" succeeds
software-post.txt - output of the software packages installed on machine "MACHINE" after the patching

So you could run reports on /patches/machines to verify which machines got patched, when, what was added / removed and what wen't wrong.
