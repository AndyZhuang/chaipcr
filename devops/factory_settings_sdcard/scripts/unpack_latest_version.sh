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

if ! id | grep -q root; then
	echo "must be run as root"
	exit 0
fi

if [ -e /dev/mmcblk1p4 ] ; then
	sdcard_dev="/dev/mmcblk0"
	eMMC="/dev/mmcblk1"
fi

if [ -e /dev/mmcblk0p4 ] ; then
	sdcard_dev="/dev/mmcblk1"
	eMMC="/dev/mmcblk0"
fi

if [ ! -e "${eMMC}p4" ]
then
        echo "Proper partitionining not found!"
	exit 1
fi

flush_cache_mounted () {
	sync
	command -v -- blockdev
	if [ $? -eq 0 ]
	then
		blockdev --flushbufs ${eMMC}
	fi
}

write_pt_image () {
	echo "Writing partition table image!"
	echo timer > /sys/class/leds/beaglebone\:green\:usr0/trigger
        tar xOf $image_filename_upgrade $image_filename_pt | gunzip -c | dd of=${eMMC} bs=16M
	flush_cache_mounted
	echo default-on > /sys/class/leds/beaglebone\:green\:usr0/trigger
	echo "Done writing partition table image!"
}

write_rootfs_image () {
	echo "Writing rootfs partition image!"
	echo timer > /sys/class/leds/beaglebone\:green\:usr0/trigger
        tar xOf $image_filename_upgrade $image_filename_rootfs | gunzip -c | dd of=${eMMC}p2 bs=16M
	flush_cache_mounted
	echo default-on > /sys/class/leds/beaglebone\:green\:usr0/trigger
	echo "Done writing rootfs partition image!"
}

write_data_image () {
        echo "Writing data partition image!"
        echo timer > /sys/class/leds/beaglebone\:green\:usr0/trigger
        tar xOf $image_filename_upgrade $image_filename_data | gunzip -c | dd of=${eMMC}p3 bs=16M
	flush_cache_mounted
        echo default-on > /sys/class/leds/beaglebone\:green\:usr0/trigger
        echo "Done writing data partition image!"
}

write_boot_image () {
	echo "Writing boot partition image!"
	echo timer > /sys/class/leds/beaglebone\:green\:usr0/trigger
	tar xOf $image_filename_upgrade $image_filename_boot | gunzip -c | dd of=${eMMC}p1 bs=16M
	flush_cache_mounted
	echo default-on > /sys/class/leds/beaglebone\:green\:usr0/trigger
	echo "Done writing boot partition image!"
}

echo timer > /sys/class/leds/beaglebone\:green\:usr0/trigger

sdcard_p1="/sdcard/p1"
sdcard_p2="/sdcard/p2"

image_filename_prfx="upgrade"
image_filename_rootfs="$image_filename_prfx-rootfs.img.gz"
image_filename_data="$image_filename_prfx-data.img.gz"
image_filename_boot="$image_filename_prfx-boot.img.gz"
image_filename_pt="$image_filename_prfx-pt.img.gz"

image_filename_upgrade="${sdcard_p2}/upgrade.img.tar"

if [ "$1" = "factorysettings" ]
then
	echo performing factory settings image
	image_filename_upgrade="${sdcard_p1}/factory_settings.img.tar"
else
	echo performing upgrade
fi

mount | grep ${eMMC}p1
if [ $? -gt 0 ]
then
	umount ${eMMC}p1
fi

mount | grep ${eMMC}p2
if [ $? -gt 0 ]
then
	umount ${eMMC}p2
fi

mount | grep ${eMMC}p3
if [ $? -gt 0 ]
then
	umount ${eMMC}p3
fi

mount | grep ${eMMC}p4
if [ $? -gt 0 ]
then
	umount ${eMMC}p4
fi

if [ ! -e ${sdcard_p1} ]
then
       mkdir -p ${sdcard_p1}
fi

if [ ! -e ${sdcard_p2} ]
then
       mkdir -p ${sdcard_p2}
fi

if [ ! -e /tmp/emmcboot ]
then
       mkdir -p /tmp/emmcboot
fi

if mount | grep ${sdcard_p1}
then
        echo "sdcard partitions mounted already!"
else
        mount ${sdcard_dev}p1 ${sdcard_p1} -t vfat || true
        mount ${sdcard_dev}p2 ${sdcard_p2} -t ext4 || true
fi

NOW=$(date +"%m-%d-%Y %H:%M:%S")

unpack_resume_flag_up () {
	echo "Upgrade resume flag up!"
	echo "Upgrade started at: $NOW">>${sdcard_p2}/unpack_resume_autorun.flag
}

if [ ! -e  $image_filename_upgrade ]
then
	echo "Image not found: $image_filename_upgrade.. exit!"
	if [ -e ${sdcard_p1}/unpack_resume_autorun.flag ]
	then
		rm ${sdcard_p1}/unpack_resume_autorun.flag || true
	fi

	if [ -e ${sdcard_p2}/unpack_resume_autorun.flag ]
	then
		rm ${sdcard_p2}/unpack_resume_autorun.flag || true
	fi

	echo default-on > /sys/class/leds/beaglebone\:green\:usr0/trigger
	echo default-on > /sys/class/leds/beaglebone\:green\:usr1/trigger

	exit 0
fi

#echo "Run with $1 $2"

stage=0
counter_file=${sdcard_p2}/unpack_stage.ini

increment_stage_counter () {
	# increment and display restart counter
	counter_old=0
	counter_old=$(cat ${counter_file})
	if [ -z $counter_old ]
	then
		counter_old=0
	fi
	echo "Old counter: $counter_old"

	stage=$((counter_old+1))
	echo $stage > $counter_file
	echo "Unpacking stage: $stage"
}

reset_stage_counter () {
	echo "Resetting stage counter."
	echo 1 > ${sdcard_p2}/unpack_stage.ini
	stage=1
	echo "Unpacking stage: $stage"
}

if [ $# -eq 2 ] && [ $2 -eq 2 ]
then
	reset_stage_counter
else
	stage=$(cat ${counter_file})
	if [ -z $stage ]
	then
		stage=0
	fi
	echo "Unpacking stage: $stage"
fi

if [ $stage -lt 2 ]
then
	reset_stage_counter
	increment_stage_counter
fi

write_pt_image
if [ $stage -le 2 ]
then
	echo Partition table wrote.
	increment_stage_counter
	#reboot needs to set sdcard only
fi

update_uenv () {                                                        
# first param =2 in case of upgrade.. =1 for factory settings.                               
        echo copying coupling uEng.txt                                                           
        if [ ! -e /tmp/emmcboot ]                                                
        then                                                                     
              mkdir -p /tmp/emmcboot                                             
        fi
		                                                                       
        mount ${eMMC}p1 /tmp/emmcboot -t vfat || true                            
                                       
	echo resetting to boot switch dependant uEnv                       
        cp /sdcard/p1/uEnv.txt /tmp/emmcboot/ || true                            
        cp /mnt/uEnv.72check.txt /mnt/uEnv.txt || true                
        cp /sdcard/p1/uEnv.72check.txt /sdcard/p1/uEnv.txt || true                
        cp /tmp/emmcboot/uEnv.72check.txt /tmp/emmcboot/uEnv.txt || true                            

        if [ $1 -eq 2 ]                                             
        then                                                                                     
                if [ -e /sdcard/p2/scripts/replace_uEnv.txt.sh ]
                then
			echo running upgrade version of replace_uEnv.txt.sh
                        sh /sdcard/p2/scripts/replace_uEnv.txt.sh /tmp/emmcboot || true
                else
			echo running factory settings version of replace_uEnv.txt.sh while performing upgrade.
                        sh /sdcard/p1/scripts/replace_uEnv.txt.sh /tmp/emmcboot || true
                fi                                                                     
        else                                                                           
		echo running factory settings version of replace_uEnv.txt.sh
                sh /sdcard/p1/scripts/replace_uEnv.txt.sh /tmp/emmcboot || true        
        fi                                                                             

        sync                                                                                     
        sleep 5                                                                                  
        umount /tmp/emmcboot || true                                                   
}                                                                                      

# needs to add a uEnv to swtich things to sdcard
echo "Freeup boot partition during the backup process"
mount ${eMMC}p1 /tmp/emmcboot
rm /tmp/emmcboot/* > /dev/null || true
sync
sleep 3
umount /tmp/emmcboot || true
increment_stage_counter

if [ "$1" = "factorysettings" ]
then
       	write_data_image
	increment_stage_counter
fi

write_rootfs_image
increment_stage_counter

write_boot_image
increment_stage_counter

if [ "$1" = "factorysettings" ]
then
	update_uenv
else
	update_uenv 2
fi

increment_stage_counter

if [ -e ${sdcard_p1}/unpack_resume_autorun.flag ]
then
	rm ${sdcard_p1}/unpack_resume_autorun.flag || true
fi

if [ -e ${sdcard_p2}/unpack_resume_autorun.flag ]
then
	rm ${sdcard_p2}/unpack_resume_autorun.flag || true
fi

echo "Finished.. byebye!"
echo "Upgrade resume flag down!"

sync

echo default-on > /sys/class/leds/beaglebone\:green\:usr0/trigger

upgrade_autorun_flag_up () {
	echo "Autorun scripts after boot.. requested on $NOW" > ${sdcard_p2}/upgrade_autorun.flag
}

change_root_password_flag_up () {
	echo "change root password after boot.. requested on $NOW" > ${sdcard_p2}/change_root_password.flag
}

upgrade_autorun_flag_down () {
	if [ -e ${sdcard_p1}/upgrade_autorun.flag ]
	then
		rm ${sdcard_p1}/upgrade_autorun.flag || true
	fi
	if [ -e ${sdcard_p2}/upgrade_autorun.flag ]
	then
		rm ${sdcard_p2}/upgrade_autorun.flag || true
	fi
}

if [ "$1" = "factorysettings" ]
then
    	echo "Changing root password on next boot!"
	change_root_password_flag_up
else
	echo "Adding migrate autorun flag"
	upgrade_autorun_flag_up
fi

if [ "$1" != "factorysettings" ]
then
	mkdir -p /tmp/data
	mount ${eMMC}p3 /tmp/data
	if [ -e /tmp/data/.tmp/shadow.backup ] || [ -e /tmp/data/.tmp/dhclient.*.leases ]
	then
		mkdir -p /tmp/rootfs
		mount ${eMMC}p2 /tmp/rootfs
		mv /tmp/data/.tmp/shadow.backup /tmp/rootfs/etc/shadow || true
		mv /tmp/data/.tmp/dhclient.*.leases /tmp/rootfs/var/lib/dhcp/ || true
		rm -r /tmp/data/.tmp || true
		sync
		umount /tmp/rootfs || true
	fi
	umount /tmp/data || true
fi

exit 0
