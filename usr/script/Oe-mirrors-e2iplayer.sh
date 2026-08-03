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

# Cleanup Function
#########################################
print_message() {
    echo "> [$(date +'%Y-%m-%d')] $1"
}

cleanup() {
    [ -d "/CONTROL" ] && rm -rf /CONTROL >/dev/null 2>&1
    rm -f /control /postinst /preinst /prerm /postrm 2>/dev/null
    rm -f /tmp/*.ipk /tmp/*.tar.gz 2>/dev/null
    print_message "Uploaded By ElieSat"
}

# Check and Remove Plugin
#########################################
if [ -d "$plugin_path" ] || grep -q "$package" "$status_file" 2>/dev/null; then
    echo "> Plugin detected. Removing existing version, please wait..."
    sleep 2

    # Remove directory if found
    [ -d "$plugin_path" ] && rm -rf "$plugin_path" >/dev/null 2>&1

    # Remove package via package manager
    if grep -q "$package" "$status_file" 2>/dev/null; then
        $uninstall_command "$package" >/dev/null 2>&1
    fi

    echo "*******************************************"
    echo "*     Removal Completed Successfully     *"
    echo "*            Provided by Eliesat          *"
    echo "*******************************************"
    sleep 2
    exit 1
fi

# Download and Install (Runs ONLY if plugin was NOT found)
#########################################
echo "> Plugin not found. Installing latest version..."

# Ensure unzip is installed
if ! command -v unzip >/dev/null 2>&1; then
    echo "> Installing missing dependency: unzip..."
    if [ "$package_manager" = "apt" ]; then
        apt-get update && apt-get install -y unzip
    else
        opkg update && opkg install unzip
    fi
fi

# Clean up any leftover temp files first
rm -rf /tmp/e2iplayer-python3.zip /tmp/e2iplayer-python3

# Download with strict output redirect
wget --no-check-certificate "https://github.com/oe-mirrors/e2iplayer/archive/refs/heads/python3.zip" -O /tmp/e2iplayer-python3.zip

# Check if zip file actually exists and has content
if [ -s /tmp/e2iplayer-python3.zip ]; then
    # Overwrite without prompting (-o) to avoid stdio hanging
    unzip -o -q /tmp/e2iplayer-python3.zip -d /tmp/ < /dev/null
    
    if [ -d "/tmp/e2iplayer-python3/IPTVPlayer" ]; then
        cp -rf /tmp/e2iplayer-python3/IPTVPlayer /usr/lib/enigma2/python/Plugins/Extensions/
        rm -f /tmp/e2iplayer-python3.zip
        rm -rf /tmp/e2iplayer-python3
        
        cleanup
        echo "> Installation completed successfully!"
    else
        echo "> Error: Extracted files not found."
        exit 1
    fi
else
    echo "> Error: Download failed or file is empty."
    exit 1
fi
