#!/bin/sh

sox -r 16000 -t ossdsp /dev/dsp $1  vol 20db silence -l 1 0.05 10% 1 2.0 10% &
echo $!