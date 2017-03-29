#!/bin/sh

CATALOGER=~/bin/cataloger
CLASS_NAME=TestAsset

if [ ! -x "${CATALOGER}" ]; then
    echo "cataloger not found" > /dev/stderr
    exit 0
fi

if [ "${SCRIPT_INPUT_FILE_COUNT}" != "1" ]; then
    echo "error: Run this from an Xcode build phase, with your xcassets file as input and your source directory as output" > /dev/stderr
    exit 1
fi

if [ "${SCRIPT_OUTPUT_FILE_COUNT}" != "1" ]; then
    echo "error: Run this from an Xcode build phase, with your xcassets file as input and your source directory as output" > /dev/stderr
    exit 1
fi

"${CATALOGER}" generate --lang objc --type class --name "${CLASS_NAME}" --output "${SCRIPT_OUTPUT_FILE_0}" "${SCRIPT_INPUT_FILE_0}"

