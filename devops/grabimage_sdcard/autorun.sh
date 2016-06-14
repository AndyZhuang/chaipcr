#!/bin/sh
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

#exit 0

id | grep -q root
is_root=$?
#echo $is_root

if [ ! $is_root ]
then
	echo "must be run as root"
	exit
fi

if [ -e /dev/mmcblk0p3 ]
then
        eMMC=/dev/mmcblk0
	sdcard_dev=/dev/mmcblk1p1
elif [ -e /dev/mmcblk1p3 ]
then
       	eMMC=/dev/mmcblk1
	sdcard_dev=/dev/mmcblk0p1
else
       	echo "3 partitions eMMC not found!"
	echo default-on > /sys/class/leds/beaglebone\:green\:usr1/trigger

	eMMC=/dev/mmcblk1
        sdcard_dev=/dev/mmcblk0p1
fi

sync
script=$(readlink -f "$0")
bin_dir=$(dirname $script)
echo Executing from: $bin_dir
mount -t tmpfs tmpfs /tmp

if [ ! -e /tmp/sdcard ]
then
	mkdir -p /tmp/sdcard
fi

if [ ! -e /tmp/emmcboot ]
then
	mkdir -p /tmp/emmcboot
fi

sdcard="/tmp/sdcard"
mount $sdcard_dev $sdcard || true

flush_cache () {
	sync
}

flush_cache_mounted () {
	sync
#	blockdev --flushbufs ${eMMC} || true
}

alldone () {
	if [ -e /sys/class/leds/beaglebone\:green\:usr0/trigger ] ; then
		echo default-on > /sys/class/leds/beaglebone\:green\:usr0/trigger
		echo default-on > /sys/class/leds/beaglebone\:green\:usr1/trigger
		echo default-on > /sys/class/leds/beaglebone\:green\:usr2/trigger
		echo default-on > /sys/class/leds/beaglebone\:green\:usr3/trigger
	fi

	echo "Done!"

	echo "Rebooting..."
	sync

	reboot
	exit 0
}

flush_cache () {
	sync
}

reset_uenv () {
	echo "resetting uEnv!"
	cp ${sdcard}/uEnv.72check.txt ${sdcard}/uEnv.txt

        mkdir -p /tmp/emmcboot
        mount ${eMMC}p1 /tmp/emmcboot -t vfat

	cp /tmp/emmcboot/uEnv.72check.txt /tmp/emmcboot/uEnv.txt
	sync
#exit
 	umount /tmp/emmcboot
	rm -r /tmp/emmcboot
        echo "Done returning to gpio 72 check version"
}

stop_packing_restarting ()
{
	reset_uenv
	if [ -e ${sdcard}/pack_resume_autorun.flag ]
	then
        	rm ${sdcard}/pack_resume_autorun.flag
	fi

	if [ -e ${sdcard}/unpack_resume_autorun.flag ]
	then
        	rm ${sdcard}/unpack_resume_autorun.flag
	fi
}

incriment_restart_counter () {
	# Incriment and display restart counter
	counter_file=${sdcard}/restart_counter.ini
	counter_old=$(cat ${counter_file})
	counter=$((counter_old+1))
	echo $counter > $counter_file
	echo "Restart counter: $counter"
}

counter=2

if [ -e ${sdcard}/pack_resume_autorun.flag ]
then
	echo "Resume eMMC packing flag found up"
	incriment_restart_counter

	if [ "$counter" -ge 5 ]
	then
		echo Restart counter exceeded 4.. quitting packing operation
		stop_packing_restarting
		echo Rebooting
		reboot
		exit 0
	fi

	echo "Resuming eMMC packing"

	sh $bin_dir/pack_latest_version.sh || true
	result=$?
	if [ $result -eq 1 ]
	then
		echo Error packing eMMC, restarting...
		reboot
		exit 0
	fi

	update_uenv
	stop_packing_restarting
	alldone
	exit
fi

#if [ ! -e ${sdcard}/factory_settings.img.gz ]
#then
	echo "Creating factory settings images! Copying from eMMC at $eMMC to sdcard at $sdcard_dev!"
	sh $bin_dir/pack_latest_version.sh || true
	sync
#	echo Creating factory settings image done.. Now creating upgrade image. 	
	echo timer > /sys/class/leds/beaglebone\:green\:usr1/trigger
	alldone
	exit 0
#fi

echo "eMMC Grabber: all done!"
sync
sleep 5
umount /tmp/sdcard > /dev/null || true

alldone

reboot
