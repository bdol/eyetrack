#!/bin/bash
# Runs through all the images in the input directory, and crops and saves any
# detected faces in the image. Note that this script requires coreutils.
#
# Brian Dolhansky, 2013.
# bdol@seas.upenn.edu

if [[ $# -lt 3 ]] 
then
    echo "Usage: ./get_faces_from_dir <input_dir> <output_dir> <crop_square_size>"
fi

# OpenCV in Python chokes if you don't give it absolute paths, so ensure the
# inputs to this function are absolute.
if [[ "$1" != /* ]]
then
   IN_DIR=$(readlink -f $1) 
else
   IN_DIR=$1
fi

if [[ "$2" != /* ]]
then
   OUT_DIR=$(readlink -f $2) 
else
   OUT_DIR=$2
fi
mkdir -p $OUT_DIR

IN_FILES=$IN_DIR/*.png
FRONT_CASCADE="$PWD/haar/haarcascade_frontalface_alt2.xml"
PROFILE_CASCADE="$PWD/haar/haarcascade_profileface.xml"
for f in $IN_FILES
do
    ./face_extract.py $f $FRONT_CASCADE $PROFILE_CASCADE $3
    IN_FILE=${f%.*}
    OUT_FILE=$OUT_DIR/${IN_FILE##*/}_cropped.jpg
    mv im_crop.jpg $OUT_FILE
done
