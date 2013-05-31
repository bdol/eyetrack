#!/usr/bin/python

import os, subprocess, sys

if len(sys.argv)<3:
    print "Usage: ./gen_file_corresp <path_to_image_root> <corr_data_dir>"
    sys.exit(1)

