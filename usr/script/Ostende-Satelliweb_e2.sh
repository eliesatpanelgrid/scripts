#!/bin/sh

opkg install transmission transmission-client python3-transmission-rpc xz

wget -q --no-check-certificate http://dreambox4u.com/dreamarabia/Satelliweb_e2/install_satelliweb_test.sh -O - | bash