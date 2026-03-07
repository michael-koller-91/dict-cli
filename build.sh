#!/usr/bin/env bash
cmd="odin build . -show-timings -thread-count:4"
echo "$cmd"
eval "$cmd"
