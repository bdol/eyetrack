import os, shutil, sys

rootdir = os.path.normpath(sys.argv[1])
outdir = os.path.normpath(sys.argv[2])

im_count = 0
for root, subFolders, files in os.walk(rootdir):
    for f in files:
        fOrig = os.path.join(root, f)
        fCopy = os.path.join(outdir, str(im_count/3)+"_"+f)
        shutil.copy(fOrig, fCopy)
        im_count += 1
