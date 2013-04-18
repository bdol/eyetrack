#!/usr/bin/python

import os, sys

if len(sys.argv)<2:
    print "Usage: ./gen_file_corresp <path_to_image_root>"
    sys.exit(1)

root = sys.argv[1]
outFile = "im_files.txt"
f = open(outFile, "w")

# First get all the subject number base paths
subjNumPaths = set([])
for path, subdirs, files in os.walk(root):
    for name in files:
        if name[0:2]=="IM":
            experimentName = os.path.basename(os.path.normpath(path))
            subjNumPath = path[0:-1]
            if subjNumPath not in subjNumPaths:
                subjNumPaths.add(subjNumPath)

# Now generate the file list
for subjNumPath in subjNumPaths:
    canonicalPath = ""

    # First let's find the canonical image
    # It helps out the face tracker if we start with this one
    for expType in ["N", "P", "E"]:
        fList = os.listdir(subjNumPath+expType)
        if "IM_For_Katie_0.png" in fList:
            canonicalPath = subjNumPath+expType+"/IM_For_Katie_0.png"

    # Now let's generate the file list itself
    f.write("!\n")
    f.write(canonicalPath+"\n")
    for expType in ["N", "P", "E"]:
        f.write("~"+expType+"\n")
        fList = os.listdir(subjNumPath+expType)
        for im in fList:
            if im[0:2]=="IM" and im[3]!="F": # Don't include the images for Katie
                f.write(subjNumPath+expType+"/"+im+"\n")
f.close()

# Now using this file list, generate the correspondences
imFile = open(outFile, "r")
f = open("file_corresp.txt", "w")


f.close()
