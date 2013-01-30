#!/bin/bash

# Create a single voice command and encode it in .mp3 format.
# This was created on OSX 10.8
# Brian Dolhansky 2013.
# bdol@seas.upenn.edu

say $1 -o $2.aiff
lame --quiet $2.aiff $2.mp3
rm -f $2.aiff
