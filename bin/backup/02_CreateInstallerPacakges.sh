#!/bin/bash -e -x


INSTALLER_FILE="/Applications/Install OS X Mavericks.app/Contents/SharedSupport/InstallESD.dmg"
INSTALLER_MOUNT="/Volumes/install_app"

OSX_NAME="MacOSX-10.9"
IMAGE_FILE="./${OSX_NAME}"
IMAGE_MOUNT="/Volumes/install_build"


# Make sure sparse image file is not mounted and 8g in size
hdiutil detach "${IMAGE_MOUNT}" || true
hdiutil resize -size 8g "${IMAGE_FILE}.sparseimage"


# Mount the sparse bundle for modifications
hdiutil attach "${IMAGE_FILE}.sparseimage" -noverify -nobrowse -mountpoint "${IMAGE_MOUNT}"


# Remove all problematic kexsts
mkdir "${IMAGE_MOUNT}/Packages" || true


# Unmount the sparse bundle
hdiutil detach "${IMAGE_MOUNT}"
