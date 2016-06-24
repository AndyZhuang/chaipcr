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
	exit 1
fi

current_folder=$(pwd)
input_dir=$current_folder
BASEDIR=$(dirname $0)

print_usage_exit () {
	echo ""
	echo "Usage: create_sdcard.sh <image folder> <block device>"
	echo "	<image folder>: the folder with factory and upgrade images"
	echo "	under <image folder>/p1 and <image folder>/p2."
	echo "	<block device>: SDCard output Block device."
	echo ""
	exit 1
}

if [ "$1" = "man" ]
then
	print_usage_exit
fi

if [ -z $1 ]
then
	echo "No images path given."
	print_usage_exit
else
	input_dir=$1
	if [ -e $1 ]
	then
		echo "Path found: $1"
	else
		mkdir -p $1
		if [ -e $1 ]
		then
			echo "Path created: $1"
			BASEDIR=$(dirname $0)
			echo copying card contents from $BASEDIR/factory_settings_sdcard/ to $input_dir/p1
			if [ ! -e ${input_dir}/p1 ]
			then
				mkdir -p ${input_dir}/p1
			fi
			cp -r $BASEDIR/factory_settings_sdcard/* $input_dir/p1
		else
			echo "Cann't create path: $1"
			print_usage_exit
		fi
	fi
fi

if [ -z $2 ]
then
	echo "No output device path given. Exit!"
	print_usage_exit
else
	output_device=$2
	if [ -e $2 ]
	then
		echo "Device found: $2"
	fi
fi

if [ ! -e ${input_dir}/p1 ]
then
	echo "Can't find input folder: ${input_dir}/p1"
	print_usage_exit
fi

if [ ! -e ${input_dir}/p2 ]
then
	echo "Can't find input folder: ${input_dir}/p2"
	print_usage_exit
fi

if [ ! -e ${output_device} ]
then
	echo "Output device not found: ${output_device}"
	print_usage_exit
fi

image_filename_upgrade1="${input_dir}/p2/upgrade.img.tar"
image_filename_upgrade2="${input_dir}/p1/factory_settings.img.tar"

if [ ! -e $image_filename_upgrade1 ]
then
	echo "Can't find input image: $image_filename_upgrade1"
	print_usage_exit
fi

if [ ! -e $image_filename_upgrade2 ]
then
	echo "Can't find input image: $image_filename_upgrade2"
	print_usage_exit
fi

if [ -z $2 ]
then
	echo "Block device dose not exist."
	print_usage_exit
fi

if [ ! -b $2 ]
then
	echo "Entered is not a block device: $2"
	print_usage_exit
fi

output_device=$2

unmount_all_debug() {
	for n in ${output_device}* ; do echo Unmounting $n ; umount $n ; done
}
unmount_all() {
	unmount_all_debug > /dev/null 2>&1 || true
}

single_partition_expand() {
        echo "${output_device}p1" > /resizerootfs
        conf_boot_startmb=${conf_boot_startmb:-"1"}
        sfdisk_fstype=${sfdisk_fstype:-"L"}
        if [ "x${sfdisk_fstype}" = "x0x83" ] ; then
                sfdisk_fstype="L"
        fi

        sfdisk_options="--force --no-reread --Linux --in-order --unit M"
        test_sfdisk=$(LC_ALL=C sfdisk --help | grep -m 1 -e "--in-order" || true )
        if [ "x${test_sfdisk}" = "x" ] ; then
                echo "sfdisk: 2.26.x or greater"
                sfdisk_options="--force --no-reread"
                conf_boot_startmb="${conf_boot_startmb}M"
        fi

  #      echo "LC_ALL=C sfdisk ${sfdisk_options} ${output_device} <<-__EOF__
   #             ${conf_boot_startmb},,${sfdisk_fstype},*
    #    __EOF__"

       LC_ALL=C sfdisk --force -uS --Linux "${output_device}" <<-__EOF__
                ${conf_boot_startmb},,${sfdisk_fstype},*
	__EOF__
        blockdev  --rereadpt "${output_device}"
	unmount_all

}

flush_cache () {
        sync
        blockdev --flushbufs "${output_device}"
	unmount_all
	blockdev  --rereadpt "${output_device}"
	unmount_all
}

if [ ! -e ${output_device} ]
then
	echo "Block device not found: ${output_device}"
	print_usage_exit
fi

if [[ ! "${output_device}" =~ "/dev/" ]]
then
	echo "Block device should start with /dev."
	print_usage_exit
fi

if [[ "${output_device}" =~ "/dev/sda" ]]
then
	echo "Block device should not be /dev/sda."
	print_usage_exit
fi

#mount ${output_device}1 > /dev/zero
#if [ $? -eq 0 ]
#then
#	echo "File system is already mounted: ${output_device}"
#	lsblk
#	print_usage_exit
#fi

# downloading disk image file

unmount_all

linux_kernel_image=bone-ubuntu-16.04-console-armhf-2016-06-09-2gb.img.xz
file_checksum=97df29fc24a87eff232dafd0bdf97711311fa28862fd1c5435dd87a049108861
linux_kernel_image_full_path=${input_dir}/$linux_kernel_image
linux_kernel_image_url="https://rcn-ee.com/rootfs/2016-06-09/microsd/${linux_kernel_image}"
echo Downloading kernel image to $linux_kernel_image_full_path

flush_cache

if [ ! -e $linux_kernel_image_full_path ]
then
	echo kernel image not found.. downloading from $linux_kernel_image_url
	wget $linux_kernel_image_url -O $linux_kernel_image_full_path
fi
if [ ! -e $linux_kernel_image_full_path ]
then
	echo Error downloading kernel image file. Please retry.
	exit 0
fi

check_sum=$(sha256sum $linux_kernel_image_full_path | awk '{ print $1 }' )
if [[ $check_sum == *"$file_checksum"* ]]
then
                        echo "Checksum ok!"
else
                        echo "Checksum error! please retry.. $file_checksum<>$check_sum"
			rm $linux_kernel_image_full_path
			exit 0
fi

echo "Done download successfully.. writing to disk: $output_device"
flush_cache
lsblk
sleep 10

	xzcat $linux_kernel_image_full_path | sudo dd of=${output_device}
	echo  "xzcat $linux_kernel_image_full_path | sudo dd of=${output_device}"
echo "Done writing to SDCard.. expanding.."
flush_cache
single_partition_expand
	echo Done..
sleep 10

echo debug done
flush_cache
sleep 4
lsblk
#echo "About to repartition the block device: ${output_device}.."
#echo "Press CTRL+C to stop the operatin now."

sleep 10

#echo "Unmounting..."
output_device_p1=${output_device}1
#output_device_p2=${output_device}2
if [[ "${output_device}" =~ "/dev/mmc" ]]
then
	output_device_p1=${output_device}p1
#	output_device_p2=${output_device}p2
fi

echo "SDCard partition is at: $output_device_p1"

umount $output_device_p1 > /dev/zero
#umount $output_device_p2 > /dev/zero
e2fsck -f "${output_device_p1}"
resize2fs -f "${output_device_p1}"
flush_cache
#echo "Partitioning.."
#dd if=/dev/zero of=${output_device} bs=1M count=16
#blockdev --flushbufs ${output_device}

#LC_ALL=C sfdisk --force -uS --Linux "${output_device}" <<-__EOF__
#1,,0xe,-
#__EOF__

#blockdev --flushbufs ${output_device}

#echo "Formating..."
#mkfs.ext4 $output_device_p1 -L factory -F -F
#if [ $? -gt 0 ]
#then
#	echo "Can't format ${output_device_p1}"
#	print_usage_exit
#fi

#mkfs.ext4 $output_device_p2 -L upgrade -F -F
#if [ $? -gt 0 ]
#then
#	echo "Can't format ${output_device_p2}"
#	print_usage_exit
#fi

sync

#lsblk

echo "Copying.."

mkdir -p /tmp/copy_mount_point
sync

mount ${output_device_p1} /tmp/copy_mount_point
if [ $? -gt 0 ]
then
	echo "Can't mount ${output_device_p1}"
	print_usage_exit
fi

#echo "cp -r $input_dir/p1/* /tmp/copy_mount_point/"
#cp -r $input_dir/p1/am335x-boneblack.dtb /tmp/copy_mount_point/

mkdir -p /tmp/copy_mount_point/factory/
mkdir -p /tmp/copy_mount_point/upgrade/

cp -r $input_dir/p1/* /tmp/copy_mount_point/factory/

sync
#umount /tmp/copy_mount_point
#if [ $? -gt 0 ]
#then
#	echo "Can't unmount ${output_device_p1}"
#	print_usage_exit
#fi

#mount ${output_device_p2} /tmp/copy_mount_point
#if [ $? -gt 0 ]
#then
#	echo "Can't mount ${output_device_p2}"
#	print_usage_exit
#fi
cp -r $input_dir/p2/* /tmp/copy_mount_point/upgrade/
sync
umount /tmp/copy_mount_point
if [ $? -gt 0 ]
then
	echo "Can't unmount ${output_device_p2}"
	print_usage_exit
fi

rm -r /tmp/copy_mount_point

echo "All done.."

exit 0
