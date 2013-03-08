#!/usr/bin/python
"""
This program is demonstration for face and object detection using haar-like features.
The program finds faces in a camera image or video stream and displays a red box around them.

Original C implementation by:  ?
Python implementation by: Roman Stanchak, James Bowman
Modified by: Brian Dolhansky, 2013. bdol@seas.upenn.edu
"""
import sys
import cv2.cv as cv
from optparse import OptionParser

# Parameters for haar detection
# From the API:
# The default parameters (scale_factor=2, min_neighbors=3, flags=0) are tuned
# for accurate yet slow object detection. For a faster operation on real video
# images the settings are:
# scale_factor=1.2, min_neighbors=2, flags=CV_HAAR_DO_CANNY_PRUNING,
# min_size=<minimum possible face size

min_size = (20, 20)
image_scale = 2
haar_scale = 1.2
min_neighbors = 2
haar_flags = 0

FRONTAL=0
PROFILE=1

def detect_and_draw(img, front_cascade, profile_cascade):
    # allocate temporary images
    gray = cv.CreateImage((img.width,img.height), 8, 1)
    small_img = cv.CreateImage((cv.Round(img.width / image_scale),
                   cv.Round (img.height / image_scale)), 8, 1)

    # convert color input image to grayscale
    cv.CvtColor(img, gray, cv.CV_BGR2GRAY)

    # scale input image for faster processing
    cv.Resize(gray, small_img, cv.CV_INTER_LINEAR)

    cv.EqualizeHist(small_img, small_img)

    if(front_cascade):
        # Test for frontal face
        faces = cv.HaarDetectObjects(small_img, front_cascade, cv.CreateMemStorage(0),
                                     haar_scale, min_neighbors, haar_flags, min_size)
        if faces: # we've detected a face
            return [faces, FRONTAL]

        # Test for profile face
        faces = cv.HaarDetectObjects(small_img, profile_cascade, cv.CreateMemStorage(0),
                                     haar_scale, min_neighbors, haar_flags, min_size)
        if faces: # we've detected a face
            return [faces, PROFILE]

        #t = cv.GetTickCount() - t
        #print "detection time = %gms" % (t/(cv.GetTickFrequency()*1000.))
        #if faces:
            #for ((x, y, w, h), n) in faces:
                ## the input to cv.HaarDetectObjects was resized, so scale the
                ## bounding box of each face and convert it to two CvPoints
                #pt1 = (int(x * image_scale), int(y * image_scale))
                #pt2 = (int((x + w) * image_scale), int((y + h) * image_scale))

                #imgWidth, imgHeight = cv.GetSize(img)
                #croppedX = max(0, x*image_scale-w*image_scale/2) 
                #croppedY = max(0, y*image_scale-h*image_scale/2)
                #croppedW = min(imgWidth, (2*w)*image_scale)
                #croppedH = min(imgHeight, (2*h)*image_scale)

                #imgCropped = cv.CreateImage((croppedW, croppedH), img.depth, img.nChannels)
                #srcRegion = cv.GetSubRect(img, (croppedX, croppedY, croppedW, croppedH))
                #cv.Copy(srcRegion, imgCropped)
                #cv.ShowImage("cropped", imgCropped)

                #cv.Rectangle(img, pt1, pt2, cv.RGB(255, 0, 0), 3, 8, 0)

    return []

def crop_and_save(img, faces, square_size):
    face_counter = 0
    for ((x, y, w, h), n) in faces:
        # the input to cv.HaarDetectObjects was resized, so scale the
        # bounding box of each face and convert it to two CvPoints
        x_center = int((float(x*image_scale)+float((x+w)*image_scale))/2.0)
        y_center = int((float(y*image_scale)+float((y+h)*image_scale))/2.0)
        top_left = (int(x_center-square_size/2), int(y_center-square_size/2))
        bottom_right = (int(x_center+square_size/2), int(y_center+square_size/2))

        imgWidth, imgHeight = cv.GetSize(img)
        croppedX = max(0, top_left[0]) 
        croppedY = max(0, top_left[1])
        croppedW = min(imgWidth, bottom_right[0]-croppedX)
        croppedH = min(imgHeight, bottom_right[1]-croppedY)

        imgCropped = cv.CreateImage((croppedW, croppedH), img.depth, img.nChannels)
        srcRegion = cv.GetSubRect(img, (croppedX, croppedY, croppedW, croppedH))
        cv.Copy(srcRegion, imgCropped)

        cv.SaveImage("im_crop.jpg", imgCropped)

        face_counter += 1

if __name__ == '__main__':
    if len(sys.argv) < 5:
        print "Usage: python face_extract.py <input_file> <frontal_cascade> <profile_cascade> <square_size>"
        sys.exit(1)

    input_name = sys.argv[1]
    front_cascade = cv.Load(sys.argv[2])
    profile_cascade = cv.Load(sys.argv[3])
    square_size = int(sys.argv[4])

    image = cv.LoadImage(input_name, 1)
    detect_vals = detect_and_draw(image, front_cascade, profile_cascade)
    if not detect_vals: # no faces detected
        print "No faces detected!"
        sys.exit(2)

    crop_and_save(image, detect_vals[0], square_size)
    if detect_vals[1] == FRONTAL:
        print "Face detected for image: "+input_name+". Type: frontal."
    else:
        print "Face detected for image: "+input_name+". Type: profile."
