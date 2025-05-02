#!/bin/bash
if [ "$EUID" -ne 0 ];
  then echo "Please run as root by executing script with sudo."
  exit
fi

echo "Searching for Updates..."
curl "https://www.loxone.com/dede/support/downloads/" --silent > loxone.html
url=$(grep -m 1 -oE 'https://\S*-amd64.deb' loxone.html)
if [ -z "$url" ]; then
	echo "Failed downloading update information"
	exit
fi
versiononline=$(grep -oP -m 1 '(?<=<h3>Loxone App )\d+\.\d+\.\d+' loxone.html)
echo "Latest version detected: $versiononline"
version=$(apt list --installed 2>/dev/null | grep "kerberos" | awk '{print $2}')
echo "Installed-Version: $version"
echo "Downloading update package from $url"
wget $url -O "loxonelatest.deb" -q --show-progress
sudo dpkg -i "loxonelatest.deb"
echo "Fininshed install, removing old files..."
rm loxone.html
rm loxonelatest.deb
echo "Done!"

