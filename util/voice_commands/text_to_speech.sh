#!/bin/bash

say $1 -o $2.aiff
lame --quiet $2.aiff $2.mp3
rm -f $2.aiff
