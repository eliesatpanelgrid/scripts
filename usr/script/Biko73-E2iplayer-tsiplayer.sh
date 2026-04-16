#!/bin/sh

rm -rf /tmp/add_Tsplayer.tar.gz > /dev/null 2>&1

MY_SEP='============================================================='
echo $MY_SEP
echo 'Downloading 'add_Tsplayer.tar.gz' ...'
echo $MY_SEP
echo ''
wget https://raw.githubusercontent.com/biko-73/E2IPlayer/main/add_Tsplayer.tar.gz -P "/tmp/"

if [ -f /tmp/add_Tsplayer.tar.gz ]; then

	echo ''
	echo $MY_SEP
	echo 'Extracting ...'
	echo $MY_SEP
	echo ''
	tar -xf /tmp/add_Tsplayer.tar.gz -C /
	MY_RESULT=$?

	rm -f /tmp/add_Tsplayer.tar.gz > /dev/null 2>&1

	echo ''
	echo ''
	if [ $MY_RESULT -eq 0 ]; then
        echo "#########################################################"
        echo "#         TSPlayer add to E2iPlayer SUCCESSFULLY        #"
        echo "#                BY BIKO - support on                   #"
        echo "#  https://www.tunisia-sat.com/forums/threads/4029331   #"
        echo "#########################################################"
        echo "#           your Device will RESTART Now                #"
        echo "#########################################################"		
		if which systemctl > /dev/null 2>&1; then
			sleep 2; systemctl restart enigma2
		else
			init 4; sleep 4; init 3;
		fi
	else
		echo "   >>>>   INSTALLATION FAILED !   <<<<"
	fi;
	echo ''
	echo '**************************************************'
	echo '**                   FINISHED                   **'
	echo '**************************************************'
	echo ''
	exit 0
else
	echo ''
	echo "Download failed !"
	exit 1
fi
# ------------------------------------------------------------------------------------------------------------
