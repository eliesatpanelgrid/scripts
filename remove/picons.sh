#!/bin/sh

echo "> removing picons please wait..."
sleep 3s

rm -rf /usr/share/enigma2/picon > /dev/null 2>&1

rm -rf /usr/share/enigma2/XPicon/picon > /dev/null 2>&1

rm -rf /usr/share/enigma2/ZZPicon/picon > /dev/null 2>&1


rm -rf /media/hdd/picon > /dev/null 2>&1

rm -rf /media/hdd/XPicon/picon > /dev/null 2>&1

rm -rf /media/hdd/ZZicon/picon > /dev/null 2>&1

rm -rf /media/usb/picon > /dev/null 2>&1

rm -rf /media/usb/XPicon/picon > /dev/null 2>&1

rm -rf /media/usb/ZZicon/picon > /dev/null 2>&1

rm -rf /media/sdcard/picon > /dev/null 2>&1

rm -rf /media/mmc/picon > /dev/null 2>&1

rm -rf /data/picon > /dev/null 2>&1

rm -rf /picon > /dev/null 2>&1


echo "> done"
sleep 3s

exit 0

