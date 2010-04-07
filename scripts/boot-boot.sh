#!/bin/bash
#
#%stage: setup
#%depends: killprogs
#%programs:
#%modules:
#%dontshow
#
##### boot
##
## Boot into the new root.
##
## Command line parameters
## -----------------------
##


# based on rd_load_policy() from fedora 12 dracut package
selinux_load_policy()
{
	local NEWROOT=$1
	local CR="${NEWROOT}/usr/bin/chroot"

	local SELINUX="enforcing"
	[ -e "$NEWROOT/etc/selinux/config" ] && . "$NEWROOT/etc/selinux/config"

	# If SELinux is disabled exit now
	if [ $cmd_selinux = "0" ]; then
		return 0
	fi

	# Check whether SELinux is in permissive mode
	local permissive=0
	if [ $cmd_enforcing = "0" ]; then
		permissive=1
	fi

	# Attempt to load SELinux Policy
	if [ -x "$NEWROOT/usr/sbin/load_policy" -o -x "$NEWROOT/sbin/load_policy" ]; then
		local ret=0
		echo "Loading SELinux policy"
		# load_policy does mount /proc and /selinux in
		# libselinux,selinux_init_load_policy()
		if [ -x "$NEWROOT/sbin/load_policy" ]; then
			$CR "$NEWROOT" /sbin/load_policy -i
			ret=$?
		else
			$CR "$NEWROOT" /usr/sbin/load_policy -i
			ret=$?
		fi

		if [ $ret -eq 0 -o $ret -eq 2 ]; then
			return 0
		fi

		echo "Initial SELinux policy load failed."
		if [ $ret -eq 3 -o $permissive -eq 0 ]; then
			echo "Machine in enforcing mode."
			echo "Not continuing"
			sleep 100d # XXX well...
			exit 1
		fi
		return 0
	elif [ $permissive -eq 0 ]; then
		echo "Machine in enforcing mode and cannot execute load_policy."
		echo "To disable selinux, add selinux=0 to the kernel command line."
		echo "Not continuing"
		sleep 100d
		exit 1
	fi
}


# Move device nodes
/bin/mount --move /dev /root/dev
/bin/mount -t proc proc /root/proc

# SELinux load policy
selinux_load_policy "/root"

# ready to leave
cd /root
umount -l /proc
umount -l /sys

# Remove exported functions
unset check_for_device

# Export root fs information
ROOTFS_BLKDEV="$rootdev"
export ROOTFS_BLKDEV

# upstart does not export the full environment to jobs by default
# and we want our boot.* scripts to know the initrd environment for
# quite a while
# technically we only need the variables exported by initrd scripts
# and the cmdline and we'll also get thinks like HOME and PWD, but
# those are overwritten anyway
export > /root/dev/shm/initrd_exports.sh

exec /bin/run-init -c ./dev/console /root $init ${kernel_cmdline[@]}
echo could not exec run-init!
die 0
