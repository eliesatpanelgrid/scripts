#!/bin/sh

echo "> removing tuner settings please wait..."
sleep 3s
echo "> your device will restart now please wait..."
init 4
sleep 1s
sed -i '/config.Nims.0/d' /etc/enigma2/settings
sleep 1s
init 3
exit 0

