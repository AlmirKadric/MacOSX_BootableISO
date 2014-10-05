#!/bin/bash -x

# Set bash options
set -o errexit;
set -o nounset;


# Make sure required variables have been passed in
AMD_RELEASE_TAG='mach_10_9_4_bronya_rc3'

if	[ -z "${IMAGE_FILE:-}" ] ||
	[ -z "${IMAGE_MOUNT:-}" ] ||
	[ -z "${XNU_DIR:-}" ] ||
	[ -z "${DTRACE_BIN:-}" ]
then
	echo "Missing required environment variables"
	echo "This script should be called from the makefile"
	echo "run command 'make all'"
fi

# Check dependencies installed
if [ ! -e "${XNU_DIR}" ]; then
	echo "You need to run 'make deps' to continue"
	exit 1
fi


# Make sure sparse image file is not mounted and 8g in size
hdiutil detach "${IMAGE_MOUNT}" || true
hdiutil resize -size 8g "${IMAGE_FILE}.sparseimage"


# Mount the sparse bundle for modifications
hdiutil attach "${IMAGE_FILE}.sparseimage" -noverify -nobrowse -mountpoint "${IMAGE_MOUNT}"


# Extract vanilla mach_kernel from /System/Installation/Packages/BaseSystemBinaries.pkg
if [ ! -e "${IMAGE_MOUNT}/mach_kernel" ]; then
	rm -rf "./BaseSystemBinaries" || true
	pkgutil --expand "${IMAGE_MOUNT}/System/Installation/Packages/BaseSystemBinaries.pkg" "./BaseSystemBinaries"
	(cd "./BaseSystemBinaries" && cat "./Payload" | bunzip2 | cpio -iv "mach_kernel")
	cp "./BaseSystemBinaries/mach_kernel" "${IMAGE_MOUNT}/mach_kernel"
	rm -rf "./BaseSystemBinaries"
fi


# Build and install bronya's AMD patched kernel
pushd "${XNU_DIR}"
git checkout "${AMD_RELEASE_TAG}"
PATH="${PATH}:${DTRACE_BIN}" make ARCH_CONFIGS=X86_64 KERNEL_CONFIGS=RELEASE
cp "./BUILD/obj/RELEASE_X86_64/mach_kernel" "${IMAGE_MOUNT}/amd"
popd


# Unmount the sparse bundle
hdiutil detach "${IMAGE_MOUNT}"
