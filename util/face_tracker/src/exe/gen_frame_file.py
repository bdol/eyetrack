#!/usr/bin/python

import os, sys

if len(sys.argv)<3:
    print "Usage: ./track_faces_from_dir <path_to_frame_folder> <out_file>"
    sys.exit(1)

root = sys.argv[1]
outFile = sys.argv[2]
f = open(outFile, "w")

for path, subdirs, files in os.walk(root):
    for name in files:
        if name[0:2]=="IM":
            fName = os.path.join(path, name)
            f.write(fName+"\n")

f.close()
