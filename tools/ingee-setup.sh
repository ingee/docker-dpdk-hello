#! /bin/bash

cd $(dirname ${BASH_SOURCE[0]})/..
export RTE_SDK=$PWD
export RTE_TARGET=x86_64-native-linuxapp-gcc
echo "------------------------------------------------------------------------------"
echo " RTE_SDK exported as $RTE_SDK"
echo " RTE_TARGET exported as $RTE_TARGET"
echo "------------------------------------------------------------------------------"

HUGEPGSZ=`cat /proc/meminfo  | grep Hugepagesize | cut -d : -f 2 | tr -d ' '`

create_mnt_huge()
{
	echo "Creating /mnt/huge and mounting as hugetlbfs"
	 mkdir -p /mnt/huge

	grep -s '/mnt/huge' /proc/mounts > /dev/null
	if [ $? -ne 0 ] ; then
		 mount -t hugetlbfs nodev /mnt/huge
	fi
}

remove_mnt_huge()
{
	echo "Unmounting /mnt/huge and removing directory"
	grep -s '/mnt/huge' /proc/mounts > /dev/null
	if [ $? -eq 0 ] ; then
		 umount /mnt/huge
	fi

	if [ -d /mnt/huge ] ; then
		 rm -R /mnt/huge
	fi
}

remove_igb_uio_module()
{
	echo "Unloading any existing DPDK UIO module"
	/sbin/lsmod | grep -s igb_uio > /dev/null
	if [ $? -eq 0 ] ; then
		 /sbin/rmmod igb_uio
	fi
}

load_igb_uio_module()
{
	if [ ! -f $RTE_SDK/$RTE_TARGET/kmod/igb_uio.ko ];then
		echo "## ERROR: Target does not have the DPDK UIO Kernel Module."
		echo "       To fix, please try to rebuild target."
		return
	fi

	remove_igb_uio_module

	/sbin/lsmod | grep -s uio > /dev/null
	if [ $? -ne 0 ] ; then
		modinfo uio > /dev/null
		if [ $? -eq 0 ]; then
			echo "Loading uio module"
			 /sbin/modprobe uio
		fi
	fi

	# UIO may be compiled into kernel, so it may not be an error if it can't
	# be loaded.

	echo "Loading DPDK UIO module"
	 /sbin/insmod $RTE_SDK/$RTE_TARGET/kmod/igb_uio.ko
	if [ $? -ne 0 ] ; then
		echo "## ERROR: Could not load kmod/igb_uio.ko."
		quit
	fi
}


clear_huge_pages()
{
	echo > .echo_tmp
	for d in /sys/devices/system/node/node? ; do
		echo "echo 0 > $d/hugepages/hugepages-${HUGEPGSZ}/nr_hugepages" >> .echo_tmp
	done
	echo "Removing currently reserved hugepages"
	 sh .echo_tmp
	rm -f .echo_tmp

	remove_mnt_huge
}

set_non_numa_pages()
{
	clear_huge_pages

	echo ""
#ingee
	Pages=1024
	echo "Number of pages: $Pages"

	echo "echo $Pages > /sys/kernel/mm/hugepages/hugepages-${HUGEPGSZ}/nr_hugepages" > .echo_tmp

	echo "Reserving hugepages"
	 sh .echo_tmp
	rm -f .echo_tmp

	create_mnt_huge
}

show_nics()
{
	if [ -d /sys/module/vfio_pci -o -d /sys/module/igb_uio ]; then
		${RTE_SDK}/tools/dpdk_nic_bind.py --status
	else
		echo "# Please load the 'igb_uio' or 'vfio-pci' kernel module before "
		echo "# querying or adjusting NIC device bindings"
	fi
}

bind_nics_to_igb_uio()
{
	if [ -d /sys/module/igb_uio ]; then
		${RTE_SDK}/tools/dpdk_nic_bind.py --status
		echo ""
#ingee
		PCI_PATH=0000:00:08.0
		echo -n "PCI address of device to bind to IGB UIO driver: $PCI_PATH "
		 ${RTE_SDK}/tools/dpdk_nic_bind.py -b igb_uio $PCI_PATH && echo "OK"

		PCI_PATH=0000:00:09.0
		echo -n "PCI address of device to bind to IGB UIO driver: $PCI_PATH "
		 ${RTE_SDK}/tools/dpdk_nic_bind.py -b igb_uio $PCI_PATH && echo "OK"
	else
		echo "# Please load the 'igb_uio' kernel module before querying or "
		echo "# adjusting NIC device bindings"
	fi
}

#echo ""
#echo "========================"
#echo "===== load IGB UIO ====="
#load_igb_uio_module

echo ""
echo "======================================"
echo "===== set HugePages for non-NUMA ====="
set_non_numa_pages

#echo ""
#echo "================================"
#echo "===== bind NICs to IGB UIO ====="
#bind_nics_to_igb_uio

#echo ""
#echo "====================="
#echo "===== show NICs ====="
#show_nics

echo ""
echo "OK"
