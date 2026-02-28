#!/usr/bin/env bash
cmd="odin build . -o:speed -show-timings -thread-count:4"
echo "$cmd"
eval "$cmd"
