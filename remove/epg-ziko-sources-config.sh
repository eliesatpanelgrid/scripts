#!/bin/sh

echo "> removing sources files please wait..."
sleep 3s

rm -rf /etc/epgimport/custom.sources.xml >/dev/null 2>&1

rm -rf /etc/epgimport/ziko_config/*.* >/dev/null 2>&1

rm -rf /etc/epgimport/ziko_epg/*.* >/dev/null 2>&1

echo "> done"
sleep 3s

exit 0