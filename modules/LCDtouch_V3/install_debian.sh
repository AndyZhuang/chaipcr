#!/bin/sh

echo "Compiling the main device tree from .dts to .dtb"
dtc -O dtb -o am335x-boneblack.dtb -b 0 -@ am335x-boneblack.dts
mv /boot/dtbs/am335x-boneblack.dtb /boot/dtbs/am335x-boneblack.orig.dtb
cp am335x-boneblack.dtb /boot/dtbs/
cp am335x-boneblack.dtb /boot/

echo "Compiling the LCD overlay from .dts to .dtbo"
dtc -O dtb -o CHAI-LCDtouch5-00A0.dtbo -b 0 -@ CHAI-LCDtouch5-00A0.dts
cp CHAI-LCDtouch5-00A0.dtbo /lib/firmware/CHAI-LCDtouch5-00A0.dtbo

#cp capemgr /etc/default/
#cp dtbo /etc/initramfs-tools/hooks/

if [ ! -e /boot/initrd.img.bak ]
then
	cp /boot/initrd.img /boot/initrd.img.bak
fi

/opt/scripts/tools/developers/update_initrd.sh

cd ft5x0x
make
ls -ahl ft5x0x_ts.ko

cp ft5x0x_ts.ko /lib/modules/$(uname -r)/kernel/drivers/input/touchscreen
depmod -a
echo ft5x0x_ts > /etc/modules-load.d/ft5x0x_ts.conf

