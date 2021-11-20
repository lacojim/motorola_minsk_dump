#!/system/bin/sh
#
# Copyright (c) 2013-2020, Motorola LLC  All rights reserved.
#

SCRIPT=${0#/system/bin/}

# function: print log into kmsg
kmsg_print() {
	echo "$SCRIPT: $1" > /dev/kmsg
}

VENDOR=`cat /sys/block/sda/device/vendor | tr -d ' '`
MODEL=`cat /sys/block/sda/device/model | tr -d ' '`
REV=`cat /sys/block/sda/device/rev`
UPGRADE_NEEDED=0

if [ $VENDOR == "SAMSUNG" ] && [ -x /system_ext/bin/sg_write_buffer ] ; then
	if [ "$MODEL" == "KLUBG4G1CE-B0B1" -o "$MODEL" == "KLUCG4J1CB-B0B1" ] ; then
		UFS_SIZE="32G"
		if [ "$REV" -lt "0800" ] ; then
			UPGRADE_NEEDED=1
		fi
	elif [ "$MODEL" == "KLUCG4J1ED-B0C1" ] ; then
		UFS_SIZE="64G"
		if [ "$REV" -lt "0200" ] ; then
			UPGRADE_NEEDED=1
		fi
	elif [ "$MODEL" == "KLUDG8V1EE-B0C1" ] ; then
		UFS_SIZE="128G"
		if [ "$REV" -lt "0400" ] ; then
			UPGRADE_NEEDED=1
		fi
	elif [ "$MODEL" == "KM5V7001DM-B621" ] ; then
		UFS_SIZE="128G"
		if [ "$REV" -lt "0610" ] ; then
			UPGRADE_NEEDED=1
		fi
	elif [ "$MODEL" == "KM2V7001CM-B706" ] ; then
		UFS_SIZE="128G"
		if [ "$REV" -ne "0800" ] ; then
			UPGRADE_NEEDED=1
		fi
	elif [ "$MODEL" == "KLUEG8UHDB-C2D1" ] ; then
		UFS_SIZE="256G"
		if [ "$REV" -lt "0900" ] ; then
			UPGRADE_NEEDED=1
		fi
	elif [ "$MODEL" == "KM5V8001DM-B622" ] ; then
		UFS_SIZE="128G"
		if [ "$REV" -eq "1300" ] ; then
			UPGRADE_NEEDED=1
		fi
	elif [ "$MODEL" == "KM2V8001CM-B707" ] ; then
		UFS_SIZE="128G"
		if [ "$REV" -eq "1300" ] ; then
			UPGRADE_NEEDED=1
		fi
	elif [ "$MODEL" == "KLUDG4UHDC-B0E1" ] ; then
		UFS_SIZE="128G"
		if [ "$REV" -lt "0200" ] ; then
			UPGRADE_NEEDED=1
		fi
	fi
elif [ $VENDOR == "SKhynix" ] && [ -x /system_ext/bin/sg_write_buffer ] ; then
	if [ "$MODEL" == "H28U74301AMR" ] ; then
		if [ "$REV" != "D003" ] ; then
			UPGRADE_NEEDED=1
		fi
	elif [ "$MODEL" == "H9HQ53AECMMDAR" ] ; then
		if [ "$REV" -lt "0004" ] ; then
			UPGRADE_NEEDED=1
		fi
	fi
elif [ $VENDOR == "WDC" ] && [ -x /product/bin/ufs_wd ] ; then
	if [ "$MODEL" == "KLUBG4G1CE-B0B1" -o "$MODEL" == "KLUCG4J1CB-B0B1" ] ; then
		UFS_SIZE="32G"
		if [ "$REV" -lt "0800" ] ; then
			UPGRADE_NEEDED=1
		fi
	elif [ "$MODEL" == "SDINDDC4-128G" ] ; then
		UFS_SIZE="128G"
		if [ "$REV" -eq "1078" -o "$REV" -eq "1076" ] ; then
			UPGRADE_NEEDED=1
		fi
	fi
elif [ $VENDOR == "MICRON" ] && [ -x /product/bin/usc_wtbuf ] ; then
	if [ "$MODEL" == "MT128GASAO4U21" ] ; then
		UFS_SIZE="128G"
		if [ "$REV" == "0106" ] ; then
			UPGRADE_NEEDED=1
		fi
	elif [ "$MODEL" == "MT256GASAO8U21" ]; then
		UFS_SIZE="256G"
		if [ "$REV" == "0106" ] ; then
			UPGRADE_NEEDED=1
		fi
	elif [ "$MODEL" == "MT064GASAO2U21" ] ; then
		UFS_SIZE="64G"
		if [ "$REV" == "0103" ] ; then
			UPGRADE_NEEDED=1
		elif [ "$REV" == "0106" ] ; then
			UPGRADE_NEEDED=1
		fi
		FW_FILE=/vendor/etc/motorola/firmware/$VENDOR-$MODEL-$UFS_SIZE-$REV.fw
	fi
elif [ $VENDOR == "KIOXIA" ] && [ -x /system_ext/bin/sg_write_buffer ] ; then
	if [ "$MODEL" == "THGJFAT1T84BAIRB" ] ; then
		UFS_SIZE="256G"
		if [ "$REV" -lt "1001" ] ; then
			UPGRADE_NEEDED=1
		fi
	fi
else
	kmsg_print "firmware upgrade feature not supported, exit..."
	exit 0
fi

kmsg_print "Vendor: $VENDOR"
kmsg_print "Model: $MODEL"
kmsg_print "Size: $UFS_SIZE"
kmsg_print "Revision: $REV"

if [ "$UPGRADE_NEEDED" == "0" ] ; then
	kmsg_print "firmware is up to date, exit..."
	exit 0
fi
if [ "$FW_FILE" = "" ] ; then
FW_FILE=/vendor/etc/motorola/firmware/$VENDOR-$MODEL-$UFS_SIZE.fw
fi

if [ -f $FW_FILE ] ; then
	kmsg_print "firmware file $FW_FILE found, upgrade now..."
else
	kmsg_print "failed to find firmware file $FW_FILE, exit..."
	exit 1
fi

sync
# Flash the firmware
if [ "$VENDOR" == "WDC" ] ; then
	/product/bin/ufs_wd  ffu -t 0 -p ./dev/block/sda -w $FW_FILE
elif [ "$VENDOR" == "MICRON" ] ; then
        /product/bin/usc_wtbuf -b 262144 -i 0 -v -I $FW_FILE -l 602112 -m 0x0e /dev/block/sda
else
	/system_ext/bin/sg_write_buffer -v -m dmc_offs_defer -I $FW_FILE  /dev/block/sda
fi

if [ $? -eq "0" ];then
	kmsg_print "upgrade done successfully, reboot now..."
	sleep 1
	echo b >/proc/sysrq-trigger
	exit 0
fi

kmsg_print "failed to upgrade!"
