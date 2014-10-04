#!/bin/bash -e -x


INSTALLER_APP="/Applications/Install OS X Mavericks.app"

OSX_NAME="MacOSX-10.9"
IMAGE_FILE="./${OSX_NAME}"
IMAGE_MOUNT="/Volumes/install_build"


# Ensure sparse image file exists
if [ ! -e "${IMAGE_FILE}.sparseimage" ]; then
	# Create new sparse image
	hdiutil create -size 8g -type SPARSE -fs HFS+ -layout GPTSPUD "${IMAGE_FILE}"

	# Mount new sparse image
	hdiutil attach "${IMAGE_FILE}.sparseimage" -noverify -nobrowse -mountpoint "${IMAGE_MOUNT}"

	# Make sparse image mavericks installer
	sudo "${INSTALLER_APP}/Contents/Resources/createinstallmedia" --nointeraction --volume "${IMAGE_MOUNT}" --applicationpath "${INSTALLER_APP}"
	hdiutil detach "/Volumes/Install OS X Mavericks"

	# Make all the files visible
	hdiutil attach "${IMAGE_FILE}.sparseimage" -noverify -nobrowse -mountpoint "${IMAGE_MOUNT}"
	sudo chflags -R nohidden "${IMAGE_MOUNT}"
	hdiutil detach "${IMAGE_MOUNT}"
fi
