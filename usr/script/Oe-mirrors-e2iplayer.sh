#!/bin/sh

# Configuration
#########################################
plugin="e2iplayer"
rm="IPTVPlayer"

plugin_path="/usr/lib/enigma2/python/Plugins/Extensions/$rm"
package="enigma2-plugin-extensions-$plugin"

# Determine package manager
#########################################
if command -v dpkg >/dev/null 2>&1; then
package_manager="apt"
status_file="/var/lib/dpkg/status"
uninstall_command="apt-get purge --auto-remove -y"
else
package_manager="opkg"
status_file="/var/lib/opkg/status"
uninstall_command="opkg remove --force-depends"
fi

# Remove package
#########################################
remove_package() {

if [ -d "$plugin_path" ]; then

echo "> removing package old version please wait..."
sleep 3

rm -rf "$plugin_path" >/dev/null 2>&1

if grep -q "$package" "$status_file" 2>/dev/null; then
echo "> Removing existing $package package, please wait..."
$uninstall_command "$package" >/dev/null 2>&1
fi

echo "*******************************************"
echo "*        Removal Completed Successfully   *"
echo "*            Provided by Eliesat          *"
echo "*******************************************"
sleep 3
exit 1
else
echo
sleep 2

fi

}

remove_package

# Cleanup
#########################################
print_message() {
echo "> [$(date +'%Y-%m-%d')] $1"
}

cleanup() {
[ -d "/CONTROL" ] && rm -rf /CONTROL >/dev/null 2>&1
rm -f /control /postinst /preinst /prerm /postrm 2>/dev/null
rm -f /tmp/*.ipk /tmp/*.tar.gz >/dev/null 2>&1
print_message "> Uploaded By ElieSat"
}

cleanup

wget --no-check-certificate "https://github.com/oe-mirrors/e2iplayer/archive/refs/heads/python3.zip" -O /tmp/e2iplayer-python3.zip && unzip /tmp/e2iplayer-python3.zip -d /tmp/ && cp -rf /tmp/e2iplayer-python3/IPTVPlayer /usr/lib/enigma2/python/Plugins/Extensions && rm -f /tmp/e2iplayer-python3.zip && rm -fr /tmp/e2iplayer-master

