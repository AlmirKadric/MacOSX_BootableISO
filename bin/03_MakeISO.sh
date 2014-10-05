#!/bin/bash -e -x

# Set bash options
set -o errexit;
set -o nounset;


# Make sure required variables have been passed in
if	[ -z "${IMAGE_FILE:-}" ] ||
	[ -z "${IMAGE_MOUNT:-}" ]
then
	echo "Missing required environment variables"
	echo "This script should be called from the makefile"
	echo "run command 'make all'"
	exit 1
fi


# Resize the partition in the sparse bundle to remove any free space
hdiutil detach "${IMAGE_MOUNT}" || true
hdiutil resize -size $(hdiutil resize -limits "${IMAGE_FILE}.sparseimage" | tail -n 1 | awk '{ print $1 }')b "${IMAGE_FILE}.sparseimage"


# Convert the sparse bundle to ISO/CD master
rm -f "${IMAGE_FILE}.iso" || true

hdiutil attach "${IMAGE_FILE}.sparseimage" -noverify -nobrowse -mountpoint "${IMAGE_MOUNT}"
sudo hdiutil makehybrid -iso -hfs -joliet -eltorito-boot "${IMAGE_MOUNT}/usr/standalone/i386/cdboot" -no-emul-boot "${IMAGE_MOUNT}" -o "${IMAGE_FILE}"
hdiutil detach "${IMAGE_MOUNT}"


# Make sure sparse image file is reverted back to 8g in size
hdiutil resize -size 8g "${IMAGE_FILE}.sparseimage"
