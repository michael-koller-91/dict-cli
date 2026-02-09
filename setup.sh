#!/usr/bin/env bash

mkdir downloads

# download and unpack Odin
wget https://github.com/odin-lang/Odin/releases/download/dev-2025-12a/odin-linux-amd64-dev-2025-12a.tar.gz
tar -xf odin-linux-amd64-dev-2025-12a.tar.gz
rm odin-linux-amd64-dev-2025-12a.tar.gz
# move to downloads
mv odin-linux-amd64-nightly+2025-12-04 downloads
