#!/bin/bash

# Set bash options
set -o errexit;
set -o nounset;


# Make sure required variables have been passed in
if	[ -z "${DTRACE_DIR:-}" ] ||
	[ -z "${DTRACE_URL:-}" ]
then
	echo "Missing required environment variables"
	echo "This script should be called from the makefile"
	echo "run command 'make deps'"
	exit 1
fi


# Create dtrace folder and get package
if [ ! -d "${DTRACE_DIR}" ]; then
	mkdir -p "${DTRACE_DIR}"
	dtBase="$(basename "${DTRACE_DIR}")"
	curl "${DTRACE_URL}" | tar -x -C "${DTRACE_DIR}" -s "/^${dtBase}//"
fi

# Create build folder if not already there
mkdir "${DTRACE_DIR}/obj" "${DTRACE_DIR}/sym" "${DTRACE_DIR}/dst" || true

# Build dtrace binaries if the bin folder doesnt exist
pushd "${DTRACE_DIR}"
xcodebuild install -target ctfconvert -target ctfdump -target ctfmerge ARCHS="i386 x86_64" SRCROOT=$PWD OBJROOT=./obj SYMROOT=./sym DSTROOT=./dst
popd
