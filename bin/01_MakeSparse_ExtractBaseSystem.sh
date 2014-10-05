#!/bin/bash -x

# Set bash options
set -o errexit;
set -o nounset;


# Make sure required variables have been passed in
if	[ -z "${INSTALLER_FILE:-}" ] ||
	[ -z "${INSTALLER_MOUNT:-}" ] ||
	[ -z "${IMAGE_FILE:-}" ] ||
	[ -z "${IMAGE_MOUNT:-}" ]
then
	echo "Missing required environment variables"
	echo "This script should be called from the makefile"
	echo "run command 'make all'"
	exit 1
fi


# Ensure sparse image file exists
if [ ! -e "${IMAGE_FILE}.sparseimage" ]; then
	# Mount the installer image
	hdiutil attach "${INSTALLER_FILE}" -noverify -nobrowse -mountpoint "${INSTALLER_MOUNT}"

	# Create sparse image from the boot image
	hdiutil convert "${INSTALLER_MOUNT}/BaseSystem.dmg" -format UDSP -o "${IMAGE_FILE}"

	# Unmount the installer image
	hdiutil detach "${INSTALLER_MOUNT}"
fi


# Make sure sparse image is 8g in size so that we can add modifications
hdiutil detach "${IMAGE_MOUNT}" || true
hdiutil resize -size 8g "${IMAGE_FILE}.sparseimage"


# Mount the sparse bundle for below checks and possible modifications
hdiutil attach "${IMAGE_FILE}.sparseimage" -noverify -nobrowse -mountpoint "${IMAGE_MOUNT}"


# Ensure the Packages folder from the installer image is copied into the sparse image
if [ -h "${IMAGE_MOUNT}/System/Installation/Packages" ]; then
	# Mount the installer image
	hdiutil attach "${INSTALLER_FILE}" -noverify -nobrowse -mountpoint "${INSTALLER_MOUNT}"

	# Remove Package link and replace with actual files
	rm "${IMAGE_MOUNT}/System/Installation/Packages"
	rsync --progress -rp "${INSTALLER_MOUNT}/Packages" "${IMAGE_MOUNT}/System/Installation"

	# Unmount the installer image
	hdiutil detach "${INSTALLER_MOUNT}"

fi


# Unmount the sparse bundle
hdiutil detach "${IMAGE_MOUNT}"
