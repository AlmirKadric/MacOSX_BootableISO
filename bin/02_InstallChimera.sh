#!/bin/bash -x

# Set bash options
set -o errexit;
set -o nounset;


# Make sure required variables have been passed in
if      [ -z "${IMAGE_FILE:-}" ] ||
        [ -z "${IMAGE_MOUNT:-}" ] ||
        [ -z "${CHIMERA_DIR:-}" ] ||
        [ -z "${EXTRA_DIR:-}" ]
then
        echo "Missing required environment variables"
        echo "This script should be called from the makefile"
        echo "run command 'make all'"
	exit 1
fi

# Check dependencies installed
if	[ ! -e "${CHIMERA_DIR}/sym/i386/cdboot" ] ||
	[ ! -e "${CHIMERA_DIR}/sym/i386/boot0" ] ||
	[ ! -e "${CHIMERA_DIR}/sym/i386/boot1h" ] ||
	[ ! -e "${CHIMERA_DIR}/sym/i386/boot" ] ||
	[ ! -e "${CHIMERA_DIR}/sym/i386/modules/Keylayout.dylib" ] ||
	[ ! -e "${CHIMERA_DIR}/sym/i386/modules/Resolution.dylib" ] ||
	[ ! -e "${CHIMERA_DIR}/sym/i386/modules/Sata.dylib" ]
then
	echo "Missing Chimera dependency"
        echo "Run 'make deps' to continue"
        exit 1
fi


# Make sure sparse image file is not mounted and 8g in size
hdiutil detach "${IMAGE_MOUNT}" || true
hdiutil resize -size 8g "${IMAGE_FILE}.sparseimage"


# Mount sparse image
hdiutil attach "${IMAGE_FILE}.sparseimage" -noverify -nobrowse -mountpoint "${IMAGE_MOUNT}"


# Install Chimera to sparse image
cp "${CHIMERA_DIR}/sym/i386/cdboot" "${IMAGE_MOUNT}/usr/standalone/i386/cdboot"
#cp "${CHIMERA_DIR}/sym/i386/boot0" "${IMAGE_MOUNT}/usr/standalone/i386/boot0"
#cp "${CHIMERA_DIR}/sym/i386/boot1h" "${IMAGE_MOUNT}/usr/standalone/i386/boot1h"
#cp "${CHIMERA_DIR}/sym/i386/boot" "${IMAGE_MOUNT}/usr/standalone/i386/boot"


# Setup "Extra" folder
mkdir "${IMAGE_MOUNT}/Extra" || true
mkdir "${IMAGE_MOUNT}/Extra/modules" || true
cp -rf "${EXTRA_DIR}/"* "${IMAGE_MOUNT}/Extra"
cp -rf "${CHIMERA_DIR}/Keymaps" "${IMAGE_MOUNT}/Extra"
#cp -rf "${CHIMERA_DIR}/sym/i386/modules/Keylayout.dylib" "${IMAGE_MOUNT}/Extra/modules"
cp -rf "${CHIMERA_DIR}/sym/i386/modules/Resolution.dylib" "${IMAGE_MOUNT}/Extra/modules"
cp -rf "${CHIMERA_DIR}/sym/i386/modules/Sata.dylib" "${IMAGE_MOUNT}/Extra/modules"


# Unmount images, need to sleep a bit to allow the disk to flush
sleep 1
hdiutil detach "${IMAGE_MOUNT}"
