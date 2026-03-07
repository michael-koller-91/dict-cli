#!/usr/bin/env bash
set -x
odin build . -o:speed -show-timings
time ./prepare_db
cd generated
odin build . -show-timings -build-mode:static
ls -l
set +x
