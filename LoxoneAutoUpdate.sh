#!/bin/bash
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root by executing script with sudo."
  exit
fi

# Detect system architecture and map to Loxone platform suffix
arch=$(dpkg --print-architecture 2>/dev/null || echo "amd64")
case "$arch" in
  amd64)   debarch="amd64" ;;
  arm64)   debarch="arm64" ;;
  armhf)   debarch="armv7l" ;;
  i386)    debarch="x86_64" ;;
  *)       echo "Unsupported architecture: $arch"; exit 1 ;;
esac

echo "Searching for Updates..."
html=$(curl "https://www.loxone.com/dede/support/downloads/" --silent)

# Download data is base64-encoded JSON inside data-config attributes.
# Extract the config for the Loxone App (application=app, type=release).
config_b64=$(echo "$html" | grep -oP 'data-config="\K[^"]+' | while read -r b64; do
  decoded=$(echo "$b64" | base64 -d 2>/dev/null)
  if echo "$decoded" | grep -q '"application":"app"' && echo "$decoded" | grep -q '"type":"release"'; then
    echo "$b64"
    break
  fi
done)

if [ -z "$config_b64" ]; then
  echo "Failed to find Loxone App download configuration"
  exit 1
fi

config=$(echo "$config_b64" | base64 -d)

# Extract version string
versiononline=$(echo "$config" | grep -oP '"version"\s*:\s*"\K[^"]+')
echo "Latest version detected: $versiononline"

# Extract the .deb download URL for the detected architecture
# JSON uses escaped slashes (\/) so unescape first, then extract
url=$(echo "$config" | sed 's|\\\/|/|g' | grep -oP "https://updatefiles\.loxone\.com/linux/Release/[^\"]*-${debarch}\.deb" | head -1)

if [ -z "$url" ]; then
  echo "Failed to find .deb download URL for architecture: $debarch"
  exit 1
fi

version=$(apt list --installed 2>/dev/null | grep "kerberos" | awk '{print $2}')
echo "Installed-Version: $version"
echo "Downloading update package from $url"
if ! wget "$url" -O "loxonelatest.deb" -q --show-progress; then
  echo "Error: Download failed"
  rm -f loxonelatest.deb
  exit 1
fi
if ! sudo dpkg -i "loxonelatest.deb"; then
  echo "Error: Installation failed"
  rm -f loxonelatest.deb
  exit 1
fi
echo "Finished install, removing old files..."
rm -f loxonelatest.deb
echo "Done!"

