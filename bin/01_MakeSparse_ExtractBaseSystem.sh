#!/bin/bash -e -x


INSTALLERFILE="/Applications/Install OS X Mavericks.app/Contents/SharedSupport/InstallESD.dmg"
INSTALLERMOUNT="/Volumes/install_app"

OSX_NAME="MacOSX-10.9"
IMAGEFILE="./${OSX_NAME}"
IMAGEMOUNT="/Volumes/install_build"


# Ensure sparse image file exists
if [ ! -e "${IMAGEFILE}.sparseimage" ]; then
	# Mount the installer image
	hdiutil attach "${INSTALLERFILE}" -noverify -nobrowse -mountpoint "${INSTALLERMOUNT}"

	# Create sparse image from the boot image
	hdiutil convert "${INSTALLERMOUNT}/BaseSystem.dmg" -format UDSP -o "${IMAGEFILE}"

	# Unmount the installer image
	hdiutil detach "${INSTALLERMOUNT}"
fi


# Make sure sparse image is 8g in size so that we can add modifications
hdiutil detach "${IMAGEMOUNT}" || true
hdiutil resize -size 8g "${IMAGEFILE}.sparseimage"


# Mount the sparse bundle for below checks and possible modifications
hdiutil attach "${IMAGEFILE}.sparseimage" -noverify -nobrowse -mountpoint "${IMAGEMOUNT}"


# Ensure the Packages folder from the installer image is copied into the sparse image
if [ -h "${IMAGEMOUNT}/System/Installation/Packages" ]; then
	# Mount the installer image
	hdiutil attach "${INSTALLERFILE}" -noverify -nobrowse -mountpoint "${INSTALLERMOUNT}"

	# Remove Package link and replace with actual files
	rm "${IMAGEMOUNT}/System/Installation/Packages"
	rsync --progress -rp "${INSTALLERMOUNT}/Packages" "${IMAGEMOUNT}/System/Installation"

	# Unmount the installer image
	hdiutil detach "${INSTALLERMOUNT}"

fi


# Unmount the sparse bundle
hdiutil detach "${IMAGEMOUNT}"
