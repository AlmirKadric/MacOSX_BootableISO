#!/bin/bash -e -x


INSTALLER_FILE="/Applications/Install OS X Mavericks.app/Contents/SharedSupport/InstallESD.dmg"
INSTALLER_MOUNT="/Volumes/install_app"

OSX_NAME="MacOSX-10.9"
IMAGE_FILE="./${OSX_NAME}"
IMAGE_MOUNT="/Volumes/install_build"

CHAMELEON_DIR="./Chameleon"
CHAMELEON_CODE="${CHAMELEON_DIR}/chimera"
CHAMELEON_REPO="http://forge.voodooprojects.org/svn/chameleon/branches/Chimera";


# Get Chameleon code & build it
if [ ! -d "${CHAMELEON_CODE}" ]; then
	svn co "${CHAMELEON_REPO}" "${CHAMELEON_CODE}"
fi
if [ ! -e "${CHAMELEON_CODE}/sym/i386/cdboot" ]; then
	make all -C Chameleon/chimera
fi


# Make sure sparse image file is not mounted and 8g in size
hdiutil detach "${IMAGE_MOUNT}" || true
hdiutil resize -size 8g "${IMAGE_FILE}.sparseimage"


# Mount sparse image
hdiutil attach "${IMAGE_FILE}.sparseimage" -noverify -nobrowse -mountpoint "${IMAGE_MOUNT}"


# Install Chameleon to sparse image
cp "${CHAMELEON_CODE}/sym/i386/cdboot" "${IMAGE_MOUNT}/usr/standalone/i386/cdboot"


# Setup "Extra" folder
mkdir "${IMAGE_MOUNT}/Extra" || true
mkdir "${IMAGE_MOUNT}/Extra/modules" || true
cp -rf "${CHAMELEON_DIR}/Extra/"* "${IMAGE_MOUNT}/Extra"
cp -rf "${CHAMELEON_CODE}/Keymaps" "${IMAGE_MOUNT}/Extra"
#cp -rf "${CHAMELEON_CODE}/sym/i386/modules/Keylayout.dylib" "${IMAGE_MOUNT}/Extra/modules"
cp -rf "${CHAMELEON_CODE}/sym/i386/modules/Resolution.dylib" "${IMAGE_MOUNT}/Extra/modules"
cp -rf "${CHAMELEON_CODE}/sym/i386/modules/Sata.dylib" "${IMAGE_MOUNT}/Extra/modules"


# Unmount images, need to sleep a bit to allow the disk to flush
sleep 1
hdiutil detach "${IMAGE_MOUNT}"
