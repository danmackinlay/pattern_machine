#!/bin/sh
# converts arbitrary soundfile to 16 bit mono 1-minute with 100ms fade times
# should I also coerce to 44kHz
sox -V3 "$1" -b 16 "$2" channels 1  fade 0.1 60 0.1 norm -3 dither -a
