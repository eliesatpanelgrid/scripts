#!/bin/sh

opkg install transmission transmission-client python3-transmission-rpc xz

wget -q --no-check-certificate http://dreambox4u.com/dreamarabia/Transmission_e2/Transmission_e2.sh -O - | bash