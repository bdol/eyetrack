#!/usr/bin/python

import os, subprocess, sys

if len(sys.argv)<3:
    print "Usage: ./gen_file_corresp <path_to_image_root> <corr_data_dir>"
    sys.exit(1)

root = sys.argv[1]
outFile = "im_files.txt"
f = open(outFile, "w")

# First get all the subject number base paths
subjNumPaths = []
for path, subdirs, files in os.walk(root):
    for name in files:
        if name[0:2]=="IM":
            experimentName = os.path.basename(os.path.normpath(path))
            subjNumPath = path[0:-1]
            if subjNumPath not in subjNumPaths:
                subjNumPaths.append(subjNumPath)


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
    f.write(canonicalPath.rstrip()+"\n")
    for expType in ["N", "P", "E"]:
        f.write("~"+expType+"\n")
        fList = os.listdir(subjNumPath+expType)
        for im in fList:
            if im[0:2]=="IM" and im[3]!="F": # Don't include the images for Katie
                f.write(subjNumPath+expType+"/"+im+"\n")
f.close()

# Now using this file list, generate the correspondences
startPath = os.getcwd()
binPath = "/Users/bdol/code/eyetrack/util/face_rectification/bin"
imFile = open(startPath+"/"+outFile, "r")
corrFile = open(startPath+"/fileCorresp.txt", "w")
os.chdir(binPath)

expNum = 0
while 1:
    expNameBase = os.path.basename(os.path.normpath(subjNumPaths[expNum]))
    outPath =  os.path.normpath(sys.argv[2])+"/"+expNameBase
    corrStrings = []
    skipFaceTracker = False
    
    # Skip this one, we already did it
    if os.path.exists(outPath+"E/"):
        if os.path.isfile(outPath+"E/H_27.txt"):
            #expNum += 1
            #for i in range(0, 86):
                #imFile.readline()
            skipFaceTracker = True 

    imFile.readline()
    imCanonical = imFile.readline()
    corrStrings.append([imCanonical.rstrip(), outPath+"N/H_0.txt"])
    imFile.readline()

    # Generate correspondences for "N" experiment
    f = open("frameListTemp.txt", "w")
    f.write(imCanonical)
    for i in range(1, 28):
        imName = imFile.readline()
        f.write(imName)
        corrStrings.append([imName.rstrip(), outPath+"N/H_"+str(i)+".txt"])
    f.close()

    if not os.path.exists(outPath+"N/"):
        os.mkdir(outPath+"N/")
    
    if not skipFaceTracker:
        subprocess.call(["./face_rectification", "frameListTemp.txt", outPath+"N/"])

    # Now write these to the correspondence file
    corrFile.write("!\n")
    corrFile.write(corrStrings[0][0]+" "+corrStrings[0][1]+"\n")
    corrFile.write("~N\n")
    for i in range(1, 28):
        corrFile.write(corrStrings[i][0]+" "+corrStrings[i][1]+"\n")

    # Generate correspondences for "P" experiment
    imFile.readline()
    corrStrings = []
    f = open("frameListTemp.txt", "w")
    f.write(imCanonical)
    for i in range(1, 28):
        imName = imFile.readline()
        f.write(imName)
        corrStrings.append([imName.rstrip(), outPath+"P/H_"+str(i)+".txt"])
    f.close()
    if not os.path.exists(outPath+"P/"):
        os.mkdir(outPath+"P/")

    if not skipFaceTracker:
        subprocess.call(["./face_rectification", "frameListTemp.txt", outPath+"P/"])
    # Now write these to the correspondence file
    corrFile.write("~P\n")
    for i in range(0, 27):
        corrFile.write(corrStrings[i][0]+" "+corrStrings[i][1]+"\n")

    # Generate correspondences for "E" experiment
    imFile.readline()
    corrStrings = []
    f = open("frameListTemp.txt", "w")
    f.write(imCanonical)
    for i in range(1, 28):
        imName = imFile.readline()
        f.write(imName)
        corrStrings.append([imName.rstrip(), outPath+"E/H_"+str(i)+".txt"])
    f.close()
    if not os.path.exists(outPath+"E/"):
        os.mkdir(outPath+"E/")

    # If we need to, extract the registration points
    if not skipFaceTracker:
        subprocess.call(["./face_rectification", "frameListTemp.txt", outPath+"E/"])

    # Now write these to the correspondence file
    corrFile.write("~E\n")
    for i in range(0, 27):
        corrFile.write(corrStrings[i][0]+" "+corrStrings[i][1]+"\n")

    expNum += 1
    if expNum>len(subjNumPaths)-1:
        break

corrFile.close()
imFile.close()
os.chdir(startPath)

print "Done!"
