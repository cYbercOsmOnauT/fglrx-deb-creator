#!/bin/bash

# Some Variables
FGLRX_URL="http://www2.ati.com/drivers/linux/amd-catalyst-15.9-linux-installer-15.201.1151-x86.x86_64.zip"
PATCHES_URL="https://launchpad.net/ubuntu/+archive/primary/+files/fglrx-installer_15.201-0ubuntu1.debian.tar.gz"
FILENAME_FGLRX=${FGLRX_URL:`expr match "$FGLRX_URL" '.*/'`}
FILENAME_PATCHES=${PATCHES_URL:`expr match "$PATCHES_URL" '.*/'`}
REFERER="http://support.amd.com/de-de/download/desktop?os=Linux+x86"
TITLE="Installation"
QUESTION="Would you like to install fglrx?"

# Is the GUI active?
if [ -z ${XDG_CURRENT_DESKTOP+x} ]; then
	GUI_ACTIVE=0
else
	GUI_ACTIVE=1
fi

# Clean old stuff
rm -f *.run

# Grab the Catalyst driver
wget -c --progress=bar:force --referer="$REFERER" "$FGLRX_URL"

# and unpack it
unzip "$FILENAME_FGLRX"
INSTALLER=$(ls --format=single-column *.run | head -n1)
chmod +x "$INSTALLER"
./"$INSTALLER" --extract extracted

# which Ubuntu do we have?
UBUNTU_VERSION=`lsb_release -cs`

# Grab the patches
wget -c --progress=bar:force "$PATCHES_URL"

tar xzf "$FILENAME_PATCHES"

# Put them where they belong to
cd extracted/packages/Ubuntu/dists/"$UBUNTU_VERSION"
rm dkms.conf.in
cp ../../../../../debian/dkms.conf.in .
rm dkms/patches/*
cp ../../../../../debian/dkms/patches/* dkms/patches/

# We can start to create the deb files
cd ../../../../
./ati-installer.sh `./ati-packager-helper.sh --version` --buildpkg Ubuntu/"$UBUNTU_VERSION"

# Delete all the garbage
cd ..
rm -r debian extracted "$FILENAME_FGLRX" "$FILENAME_PATCHES" *.changes

# Install it?
if [ "$GUI_ACTIVE" -eq 1 ]; then
	zenity --question --title="$TITLE" --text="$QUESTION"
	if [ $? -eq 0 ];then
		gksudo dpkg -i *.deb
	fi
else
	dialog --yesno "$QUESTION" 5 `expr ${#QUESTION} + 6`
	if [ $? -eq 0 ];then
		sudo dpkg -i *.deb
	fi
fi