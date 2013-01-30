#!/bin/bash

# This was created on OSX 10.8. Make sure you have the lame binaries installed.
# Brian Dolhansky 2013.
# bdol@seas.upenn.edu

if [ $# -ne 1 ]
then
    echo "Usage: make_speech_commands.sh <total no. of commands>"
    exit 1
fi

for i in $(eval echo {1..$1})
do
    `./text_to_speech.sh "Please look at number ${i}" command_${i}`
done
