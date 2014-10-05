#######################################
###       MacOSX Bootable ISO       ###
#######################################

# Image Variables
OSX_NAME="MacOSX-10.9"
OUTPUT_FOLDER="./output"
IMAGE_FILE="$(OUTPUT_FOLDER)/$(OSX_NAME)"
IMAGE_MOUNT="/Volumes/install_build"

# Installer variables
INSTALLER_FILE="/Applications/Install OS X Mavericks.app/Contents/SharedSupport/InstallESD.dmg"
INSTALLER_MOUNT="/Volumes/install_app"

# Extras variables
EXTRA_DIR="./deps/Extra"

# Chimera variables
CHIMERA_DIR="./deps/Chimera"
CHIMERA_REPO="http://forge.voodooprojects.org/svn/chameleon/branches/Chimera@2400"

# DTrace dependency for compiling XNU kernel
DTRACE_VERSION="118.1"
DTRACE_DIR="./deps/dtrace-$(DTRACE_VERSION)"
DTRACE_URL="http://opensource.apple.com/tarballs/dtrace/dtrace-$(DTRACE_VERSION).tar.gz"
DTRACE_BIN="$(CURDIR)/$(DTRACE_DIR)/dst/usr/local/bin"

# XNU kernel variables
XNU_REPO="https://github.com/AlmirKadric/MacOSX_xnuKernel.git"
XNU_DIR="./deps/MacOSX_xnuKernel"


# Function which calls given script with all required variables
define runWithVars
OUTPUT_FOLDER=$(OUTPUT_FOLDER) INSTALLER_FILE=$(INSTALLER_FILE) INSTALLER_MOUNT=$(INSTALLER_MOUNT) IMAGE_FILE=$(IMAGE_FILE) IMAGE_MOUNT=$(IMAGE_MOUNT) CHIMERA_DIR=$(CHIMERA_DIR) EXTRA_DIR=$(EXTRA_DIR) DTRACE_DIR=$(DTRACE_DIR) DTRACE_URL=$(DTRACE_URL) DTRACE_BIN=$(DTRACE_BIN) XNU_DIR=$(XNU_DIR) $1
endef


# Define which function are not files and should not be cached
.PHONY: help dep-chimera dep-dtrace dep-xnu deps all clean


# Help screen, this is also the default if no targets given
help:
	@echo "#######################################"
	@echo "###       MacOSX Bootable ISO       ###"
	@echo "#######################################"
	@echo "";
	@echo "make deps   Get & builds all required dependencies";
	@echo "make all    Build sparse image and bootable ISO";
	@echo "make clean  Deletes build files";
	@echo "";

# Install Chimera branch of Chameleon and only build the files we need
dep-chimera:
	if [ ! -d "$(CHIMERA_DIR)" ]; then svn co "$(CHIMERA_REPO)" "$(CHIMERA_DIR)"; fi
	make -C "${CHIMERA_DIR}" rebuild_config
	make -C "${CHIMERA_DIR}/i386" modules-builtin
	make -C "${CHIMERA_DIR}/i386/util"
	make -C "${CHIMERA_DIR}/i386/klibc"
	make -C "${CHIMERA_DIR}/i386/libsa"
	make -C "${CHIMERA_DIR}/i386/libsaio"
	make -C "${CHIMERA_DIR}/i386/boot0"
	make -C "${CHIMERA_DIR}/i386/boot1"
	make -C "${CHIMERA_DIR}/i386/boot2"
	make -C "${CHIMERA_DIR}/i386/cdboot"
	make -C "${CHIMERA_DIR}/i386/modules/Keylayout"
	make -C "${CHIMERA_DIR}/i386/modules/Resolution"
	make -C "${CHIMERA_DIR}/i386/modules/Sata"

# Get and build dtrace tools that we need for compiling XNU kernel
dep-dtrace:
	$(call runWithVars, "./bin/InstallDTrace.sh")

# Get XNU kernel source code. We don't build as this could contain
# multiple branches that we may wish to compile. That will be done
# in the install kernel step.
dep-xnu:
	if [ ! -d "$(XNU_DIR)" ]; then git clone "$(XNU_REPO)" "$(XNU_DIR)"; fi

# Get and setup all required dependencies for the main execution
deps: dep-chimera dep-dtrace dep-xnu


# The main target. This will create the ISO file
all:
	$(call runWithVars, "./bin/01_MakeSparse_ExtractBaseSystem.sh")
	$(call runWithVars, "./bin/02_InstallChimera.sh")
	$(call runWithVars, "./bin/02_InstallKernels.sh")
#	$(call runWithVars, "./bin/02_PatchKexts.sh")
#	$(call runWithVars, "./bin/02_CreateInstallerPacakges.sh")
	$(call runWithVars, "./bin/03_MakeISO.sh")


# Delete all build files and paths
clean:
	rm -f ./output/MacOSX-10.9.sparseimage
	rm -f ./output/MacOSX-10.9.iso
