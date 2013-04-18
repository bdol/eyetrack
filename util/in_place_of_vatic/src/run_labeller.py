import os
import sys
import getopt

if(len(sys.argv)<2):
    print 'Usage: python run_labeller.py <path_to_image_folder>'

elif(len(sys.argv)==1):
    count = 1
    head = sys.argv[1]
    for (dirpath, dirnames, filenames) in os.walk(head):
        for filename in filenames:
            if(filename.endswith('jpg') or filename.endswith('png') or filename.endswith('jpeg')):
                cmd = './label_interest_points ' + os.path.join(dirpath, filename) + ' ' + str(count)
                os.system(cmd)
                count = count + 1
else:
    count = 1
    for filename in sys.argv[1:]:
        if(filename.endswith('jpg') or filename.endswith('png') or filename.endswith('jpeg')):
                cmd = './label_interest_points ' + filename + ' ' + str(count)
                os.system(cmd)
                count = count + 1