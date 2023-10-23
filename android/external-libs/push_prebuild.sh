#!/bin/bash
# Script used to push changes to ci.anonero.io
# used to save time when compiling release builds.
cd "$(dirname "$0")"
set -xe
rm build.tar.gz || true
tar --use-compress-program="pigz --best --recursive" -cf build.tar.gz arm64-v8a x86_64 armeabi-v7a x86 VERSION

uname -a > builder.txt
set +e
    rsync --mkpath -raz --info=progress2 builder.txt build.tar.gz anonero@ci.anonero.io:web/ci.anonero.io/public_html/monero/"$(cat VERSION)"
    rm builder.txt
    rm build.tar.gz
set -e
