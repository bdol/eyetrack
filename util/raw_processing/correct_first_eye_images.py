#!/usr/bin/python
import re
import os
import sys

if len(sys.argv)<2:
    print "Usage: ./correct_first_eye_images.py <root_dir>"

rootDir = sys.argv[1]
s = raw_input("This is a destructive operation and should only be run ONCE! Are you sure you want to clean up the files in "+rootDir+"?\n\nPress y to continue, or any other key to quit: ")
if s!='y':
    sys.exit(0)

for root, subFolders, files in os.walk(rootDir):
    currentDir = os.path.basename(root)
    m = re.search('\d\d\d\d', currentDir)
    if m is not None: # We are in a subject directory
        print "Processing files for subject number "+m.group(0)+"."
        # First move the first images in directory number 1 to a "straight" directory
        if not os.path.exists(os.path.join(root, "straight")):
            os.mkdir(os.path.join(root, "straight"))
        if os.path.isfile(os.path.join(root, "1", "IM_1_1_left.png")):
            fOrig = os.path.join(root, "1", "IM_1_1_left.png")
            fNew = os.path.join(root, "straight", "straight_left.png")
            os.rename(fOrig, fNew)
        if os.path.isfile(os.path.join(root, "1", "IM_1_1_right.png")):
            fOrig = os.path.join(root, "1", "IM_1_1_right.png")
            fNew = os.path.join(root, "straight", "straight_right.png")
            os.rename(fOrig, fNew)

        # Now for each of the directories (1-8), move the first two images from
        # directory i+1 to directory i, and rename
        for i in range(1, 10):
            # Left
            if os.path.isfile(os.path.join(root, str(i+1), "IM_"+str(i+1)+"_1_left.png")):
                fOrig = os.path.join(root, str(i+1), "IM_"+str(i+1)+"_1_left.png")
                fNew = os.path.join(root, str(i), "IM_"+str(i)+"_1_left.png")
                os.rename(fOrig, fNew)
            # Right
            if os.path.isfile(os.path.join(root, str(i+1), "IM_"+str(i+1)+"_1_right.png")):
                fOrig = os.path.join(root, str(i+1), "IM_"+str(i+1)+"_1_right.png")
                fNew = os.path.join(root, str(i), "IM_"+str(i)+"_1_right.png")
                os.rename(fOrig, fNew)



print "Done!"
