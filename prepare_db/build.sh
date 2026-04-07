#!/usr/bin/env bash
set -ex
odin build . -o:speed -show-timings
time ./prepare_db
cd generated
odin build . -show-timings -build-mode:static
ls -l
