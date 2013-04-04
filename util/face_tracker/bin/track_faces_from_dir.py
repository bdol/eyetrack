#!/usr/bin/python

import os, subprocess, sys

if len(sys.argv)<4:
    print "Usage: ./track_faces_from_dir <path_to_tracker_bin> <path_to_root_dir> <out_dir>"
    sys.exit(1)

exe = sys.argv[1]
root = sys.argv[2]
outDir = sys.argv[3]
for path, subdirs, files in os.walk(root):
    for name in files:
        fName = os.path.join(path, name)

        if name[0]!='I':
            continue

        print "Processing",fName
        folder = os.path.basename(os.path.normpath(path))
        subprocess.call([exe, fName, outDir+"/face_"+folder+"_"+name])


