#!/usr/bin/python

import os, string, subprocess, sys

if len(sys.argv)<4:
    print "Usage: ./gen_file_list_by_substr.py <path to dir root> <substr> <file list filename>"
    sys.exit(1)

root = sys.argv[1]
substr = sys.argv[2]

outName = sys.argv[3]
f = open(outName, "w")

for path, subdirs, files in os.walk(root):
    for name in files:
        if string.find(name, substr) != -1:
            f.write(os.path.join(path, name)+"\n")

f.close()
