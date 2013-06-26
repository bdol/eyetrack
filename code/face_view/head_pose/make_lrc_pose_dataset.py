#!/usr/bin/python
import math, os, re, sys

if len(sys.argv)<5:
    print "Usage: ./make_lrc_pose_dataset.py <pose file list> <output dir> <center angle width> <out file name>"
    sys.exit(1)

poseFile = sys.argv[1]
outDir = sys.argv[2]
centerTol = float(sys.argv[3])
outFileName = sys.argv[4]

# Create the output file structure
if not os.path.exists(outDir):
    os.makedirs(outDir)
if not os.path.exists(os.path.join(outDir, "left")):
    os.makedirs(os.path.join(outDir, "left"))
if not os.path.exists(os.path.join(outDir, "center")):
    os.makedirs(os.path.join(outDir, "center"))
if not os.path.exists(os.path.join(outDir, "right")):
    os.makedirs(os.path.join(outDir, "right"))

# Iterate through the pose file list. If abs(y angle)<centerTol, then the image goes in center.
# Otherwise, it goes in left/right
counts = [0, 0, 0]
orDirs = ['left', 'right', 'center']
fOut = open(outFileName, 'w')
with open(poseFile) as f:
    content = f.readlines()
    for line in content:
        toks = re.split(',', line)
        fname = toks[0]

        # Skip first line
        if fname=='FILE NAME':
            continue

        if len(toks)>2:
            orientation = -1
            yangle = float(toks[2])
            if math.fabs(yangle)<centerTol: # center
                orientation = 1
            elif yangle < 0:                # left
                orientation = 0
            else:                           # right
                orientation = 2

            # Increment the counter for the appropriate orientation (debug purposes)
            counts[orientation] += 1

            # Assign the file orientation
            imInName = fname.replace("raw_data", "png_data")
            imInName = imInName.replace("DP", "IM")
            imInName = imInName.replace("raw", "png")
            print "Processing", imInName
            fOut.write(imInName+" "+str(orientation)+"\n")





    f.close()

fOut.close()
print "Counts (left, right, center):",counts
