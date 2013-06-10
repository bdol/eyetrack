#!/usr/bin/python

import os, subprocess, sys

if len(sys.argv)<2:
    print "Usage: ./run_test.py <lrc_root_directory>"
    sys.exit(1)

rootDir = sys.argv[1]
files = os.listdir(rootDir)

# We have 2 files per fold: train and test
N_folds = len(files)/2
for i in range(1, N_folds+1):
    trainFile = os.path.normpath(rootDir)+"/train_"+str(i)+".txt"
    testFile = os.path.normpath(rootDir)+"/test_"+str(i)+".txt"
    
    # Train the SVM
    # Parameters:
    #   -t 0: train a linear kernel
    #   -c 1E-2: the cost value C
    subprocess.call(["./svm-train", "-t", "0", "-c", "1E-2", trainFile, "train.model"])
    # Test the SVM
    subprocess.call(["./svm-predict", testFile, "train.model", "test.output"])

