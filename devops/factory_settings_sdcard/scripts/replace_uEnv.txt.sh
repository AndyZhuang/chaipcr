#!/bin/bash
#
# Chai PCR - Software platform for Open qPCR and Chai's Real-Time PCR instruments.
# For more information visit http://www.chaibio.com
#
# Copyright 2016 Chai Biotechnologies Inc. <info@chaibio.com>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

#must run as root to be able to move shadow file.
BASEDIR=$(dirname $0)
#echo "script_dir: $BASEDIR/"
boot=/boot
all="all"
if [ $# -gt 0 ]
then
	if [  "$1" = "all" ]
	then
		echo "Updating all uEnvs.."
		mkdir -p /tmp/replacer
		mount /dev/mmcblk0p1 /tmp/replacer
		echo Updating /dev/mmcblk0p1 /uEnv.txt
		sh $BASEDIR/replace_uEnv.txt.sh /tmp/replacer
		echo Updating /dev/mmcblk0p1 /boot/uEnv.txt
		sh $BASEDIR/replace_uEnv.txt.sh /tmp/replacer/boot
		umount /tmp/replacer

		mount /dev/mmcblk1p1 /tmp/replacer
		echo Updating /dev/mmcblk1p1 /uEnv.txt
		sh $BASEDIR/replace_uEnv.txt.sh /tmp/replacer
		echo Updating /dev/mmcblk1p1 /boot/uEnv.txt
		sh $BASEDIR/replace_uEnv.txt.sh /tmp/replacer/boot
		umount /tmp/replacer

		rm -r /tmp/replacer
		echo Done replacing eMMC and SDCard
		exit 0
	fi

	boot=$1
	echo "Boot partition path is: $boot"
fi

if [ ! -e $boot ]
then
	echo "Boot path not found: $boot"
	exit 1
fi

uEnv=$boot/uEnv.txt
uEnvSDCard=$boot/uEnv.sdcard.txt
uEnv72Check=$boot/uEnv.72check.txt
#echo "uEnv file is at: $uEnv"

NOW=$(date +"%m-%d-%Y %H:%M:%S")

UUID_SDCARD=$(blkid /dev/mmcblk0p1 | awk -FUUID=\" '{print $2}' | awk -F\" '{print $1}')
UUID=$(blkid /dev/mmcblk1p1 | awk -FUUID=\" '{print $2}' | awk -F\" '{print $1}')
UUID_p2=$(blkid /dev/mmcblk1p2 | awk -FUUID=\" '{print $2}' | awk -F\" '{print $1}')
UUID_p3=$(blkid /dev/mmcblk1p3 | awk -FUUID=\" '{print $2}' | awk -F\" '{print $1}')
EMMC=/dev/mmcblk1p1
SDCARD=/dev/mmcblk0p1
if [ -z $UUID_p2 ]
then
	echo "/dev/mmcblk1 is not a valid block device"
	UUID_SDCARD=$(lsblk -no UUID /dev/mmcblk1p1)
	UUID=$(lsblk -no UUID /dev/mmcblk0p1)
	UUID_p2=$(blkid /dev/mmcblk0p2 | awk -FUUID=\" '{print $2}' | awk -F\" '{print $1}')
	UUID_p3=$(blkid /dev/mmcblk0p3 | awk -FUUID=\" '{print $2}' | awk -F\" '{print $1}')
        EMMC=/dev/mmcblk0p1
	SDCARD=/dev/mmcblk1p1
	if [ -z $UUID_p2 ]
	then
		echo "Cann't find a booting root!"
		exit 0
	fi
fi

echo "Root fs Block device found at $UUID, SDCard found at $SDCARD"

echo "/data partition found at $UUID_p2"
echo "/perm partition found at $UUID_p3"

#exit

cat << _EOF_ > $uEnv

uname_r=4.4.9-ti-rt-r26
###uuid=${UUID}

s2pressed=0
shutdown_usb_power=i2c dev 0;i2c mw 0x24 1 0xec

uenvcmdmmc=echo "*** Boot button Unpressed..!!"; uuid=${UUID}
uenvcmdsdcard=uuid=${UUID_SDCARD}
uenvcmdsdcard_s2pressed=echo "*************** Boot button pressed SDCard ******";uuid=${UUID_SDCARD}; setenv s2pressed 1; run uenvcmdsdcard

uenvcmd=run shutdown_usb_power;if gpio input 72; then run uenvcmdsdcard_s2pressed; else run uenvcmdmmc; fi

cmdline=coherent_pool=1M quiet cape_universal=enable
# Updated: $NOW

_EOF_

echo "uEnv.txt done updating"

cp $uEnv $uEnvSDCard
cp $uEnv $uEnv72Check
echo " " >> $uEnvSDCard
echo "uenvcmd=run shutdown_usb_power;if gpio input 72; then run uenvcmdsdcard_s2pressed; else run uenvcmdsdcard; fi" >> $uEnvSDCard
echo "#" >> $uEnvSDCard

echo "SDCard version of uEnv.txt done updating"

if [ -z $UUID_p2 ]
then
	echo "Cann't find UUID for /data partition!"
	exit 0
fi

if [ -z $UUID_p3 ]
then
	echo "Cann't find UUID for /perm partition!"
	exit 0
fi

mkdir -p /tmp/folderscreator
mount $UUID /tmp/folderscreator
if [ ! -e /tmp/folderscreator/data ]
then
	mkdir -p /tmp/folderscreator/data 
	mkdir -p /tmp/folderscreator/perm
fi
umount /tmp/folderscreator
rm -r /tmp/folderscreator


echo "Adding automount for /data and /perm"
rootfs="/tmp/emmcrootfs"
if [ ! -e $rootfs ]
then
	mkdir -p $rootfs
fi

mount $EMMC $rootfs
fstab="$rootfs/etc/fstab"
fstab_new="$rootfs/etc/fstab_new"
if [ -e $fstab_new ]
then
	rm $fstab_new
fi

while IFS= read -r var
do
	if test "${var#*/perm}" != "$var" #[[ "$var" == *perm* ]]
	then
		echo "Removing perm line from fstab..."
		continue
	fi
        if test "${var#*/data}" != "$var" #[[ "$var" == *"data"* ]]
        then
                echo "Removing data line from fstab..."
                continue
        fi
	echo "$var"
	echo $var >> $fstab_new
done < "$fstab"

echo "UUID=$UUID_p2  /data   ext4    rw,auto,user,errors=remount-ro  0  0" >> $fstab_new
echo "UUID=$UUID_p3  /perm   ext4    rw,auto,user,errors=remount-ro  0  0" >> $fstab_new

cp $fstab "${fstab}.save"
cp $fstab_new $fstab
sync
umount $rootfs || true
rm -r $rootfs || true
echo fstab updated

exit 0
