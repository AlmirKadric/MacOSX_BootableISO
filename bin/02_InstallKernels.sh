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


# Extract vanilla mach_kernel from /System/Installation/Packages/BaseSystemBinaries.pkg
if [ ! -e "${IMAGE_MOUNT}/mach_kernel" ]; then
	rm -rf "./BaseSystemBinaries" || true
	pkgutil --expand "${IMAGE_MOUNT}/System/Installation/Packages/BaseSystemBinaries.pkg" "./BaseSystemBinaries"
	(cd "./BaseSystemBinaries" && cat "./Payload" | bunzip2 | cpio -iv "mach_kernel")
	cp "./BaseSystemBinaries/mach_kernel" "${IMAGE_MOUNT}/mach_kernel"
	rm -rf "./BaseSystemBinaries"
fi


# Copy AMD patched kernel and extensions
cp "./Kernels/mach_10_9_2_fx_bronya_rc1/mach_kernel" "${IMAGE_MOUNT}/amdfx_10.9.2_rc1"
cp "./Kernels/mach_10_9_2_fx_bronya_rc2/mach_kernel" "${IMAGE_MOUNT}/amdfx_10.9.2_rc2"
cp "./Kernels/mach_10_9_2_fx_bronya_rc3/mach_kernel" "${IMAGE_MOUNT}/amdfx_10.9.2_rc3"
cp "./Kernels/mach_10_9_2_fx_bronya_rc4/secure/mach_kernel" "${IMAGE_MOUNT}/amdfx_10.9.2_rc4"
cp "./Kernels/mach_10_9_2_fx_bronya_rc4_test/mach_kernel" "${IMAGE_MOUNT}/amdfx_10.9.2_rc4_test"
cp "./Kernels/mach_10_9_2_fx_bronya_rc5/mach_kernel" "${IMAGE_MOUNT}/amdfx_10.9.2_rc5"
cp "./Kernels/mach_10_9_2_fx_bronya_rc6/for FX/mach_kernel" "${IMAGE_MOUNT}/amdfx_10.9.2_rc6"
cp "./Kernels/mach_10_9_2_fx_bronya_rc6_fix/mach_kernel" "${IMAGE_MOUNT}/amdfx_10.9.2_rc6_fix"
cp "./Kernels/mach_10_9_4_rc1/mach_kernel" "${IMAGE_MOUNT}/amd_10.9.4_rc1"
cp "./Kernels/mach_10_9_4_rc2/mach_kernel" "${IMAGE_MOUNT}/amd_10.9.4_rc2"
cp "./Kernels/mach_10_9_4_rc3/FX/mach_kernel" "${IMAGE_MOUNT}/amd_10.9.4_rc3"


# The current blessed kernels
BLESSED_KERNEL_AMD="amd_10.9.4_rc3"
(cd "${IMAGE_MOUNT}"; ln -s "${BLESSED_KERNEL_AMD}" "amd")


# Unmount the sparse bundle
hdiutil detach "${IMAGE_MOUNT}"
