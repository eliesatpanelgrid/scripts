#!/bin/bash

clear >/dev/null 2>&1

#configuration
###########################################
plugin=main
version='scripts'
url=https://github.com/eliesat/scripts/archive/main.tar.gz
package=/tmp/$plugin.tar.gz
rm -rf /tmp/$plugin.tar.gz >/dev/null 2>&1

# Check script url connectivity and install eliesatpanel
###########################################
if wget -q --method=HEAD https://github.com/eliesat/scripts/blob/main/installer.sh; then
connection=ok
else
echo "> Server is down, try again later..."
exit 1
fi

# Functions
###########################################
print_message() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}
print_message "> Start of process ..."
echo "-----------------------------------------------"
echo
sleep 2

cleanup() {
    rm -rf /var/cache/opkg/* /var/lib/opkg/lists/* /run/opkg.lock $i >/dev/null 2>&1
}

#check print image and python version
###########################################
if [ -f /etc/image-version ]; then image_version=$(cat /etc/image-version | grep -iF "creator" | cut -d"=" -f2 | xargs) 
elif [ -f /etc/issue ]; then image_version=$(cat /etc/issue | head -n1 | awk '{print $1;}') 
else 
image='> image name not found' 
fi 

python_version=$(python -c "import platform; print(platform.python_version())")

print_message "> Image : $image_version"
sleep 2
print_message "> Python : $python_version"
sleep 2


# Remove unnecessary files and folders
###########################################
[ -d "/CONTROL" ] && rm -r /CONTROL >/dev/null 2>&1
rm -rf /control /postinst /preinst /prerm /postrm /tmp/*.ipk /tmp/*.tar.gz >/dev/null 2>&1

# Download and install eliesatpanel
###########################################
wget -qO $package --no-check-certificate $url
tar -xzf $package -C /tmp
extract=$?
rm -rf $package >/dev/null 2>&1

if [ $extract -eq 0 ]; then
    rm -rf /tmp/scripts-main/*.sh >/dev/null 2>&1
    mkdir -p /usr/script >/dev/null 2>&1
    cp -r '/tmp/scripts-main/usr' '/' >/dev/null 2>&1
    rm -rf /tmp/scripts-main >/dev/null 2>&1
print_message "> scripts are installed successfully and up to date ..."
echo
sleep 2
fi
print_message "> End of process ..."
sleep 3


