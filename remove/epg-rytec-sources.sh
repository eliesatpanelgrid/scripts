#!/bin/sh

echo "> removing sources files please wait..."
sleep 3s

cd /etc/epgimport
shopt -s extglob
rm -v !("custom.sources.xml"|"xstreamity.sources.xml") >/dev/null 2>&1
cd /


echo "> done"
sleep 3s

exit 0
