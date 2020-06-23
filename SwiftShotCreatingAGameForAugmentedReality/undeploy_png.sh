#!/bin/bash

# Remove png assets from the deploy.  We first need scnassets file to be copied in "Copy Bundle Resources"
# so that the png paths that exist are re-written to ktx assets.  Then we remove the .png assets before
# the app is signed and deployed to the device.

# only run this from the deployed app directory after "Copy Bundle Resources"
#set -x
dir=$2
safetyCheck=$1

numArgs=$#

cd "${dir}"

# prevent this from being frun
# if ktx exists, then remove the corresponding png if that exists

if [ ${numArgs} -eq 2 ] && [ ${safetyCheck} == "xcode" ]; then
    echo "Removing png files which have a corresponding ktx file."
    find . -name "*.ktx" | sed 's/.ktx/.png/' | xargs rm -f
else
    echo "Usage: $0 xcode directory"
    echo "This script requires 'xcode' safety argument and a folder to prevent accidental deletion of source textures."
    exit 1
fi
