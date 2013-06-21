//
//  main.cpp
//  KinectMinimal
//
//  Created by Brian Dolhansky on 6/18/13.
//  Copyright (c) 2013 Brian Dolhansky. All rights reserved.
//

#include <iostream>
#include <sstream>
#include <unistd.h>
#include <pthread.h>

#include <opencv2/opencv.hpp>
#include <opencv2/highgui/highgui.hpp>
#include <opencv/cvaux.h>
#include <opencv2/imgproc/imgproc.hpp>

#include "libfreenect.h"
#include <FaceTracker/Tracker.h>
#include <kinect_util/KinectFreenect.h>
#include <FaceTracker/FaceTrackerWrapper.h>
#include <libsvm/SVMWrapper.h>

using namespace cv;
using namespace std;

KinectFreenect* kinect;
Mat depthMat(Size(640, 480), CV_16UC1);
Mat rgbMat(Size(1280, 1024), CV_8UC3);
Mat leftEye, rightEye;

FaceTrackerWrapper* faceTracker;
SVMWrapper* svm;

bool update = true; // TODO: This is a pretty hacky way to deal with updating images on a thread

void updateDrawnPredictions(double* prob_estimates) {
    if (prob_estimates != NULL) {
        for (int i=0; i<3; i++) {
            stringstream predVal;
            int predNum = i+1;
            switch(predNum) {
                double p;
                case 1:
                    p = prob_estimates[i];
                    predVal << "L: " << p;
                    putText(rgbMat, predVal.str(), Point(30, 30), CV_FONT_HERSHEY_PLAIN, 1, Scalar(255, 255, 255));
                    rectangle(rgbMat, Point(30, 40), Point(p*300.0+30, 50), Scalar(255, 0, 0), CV_FILLED);
                    break;
                case 2:
                    p = prob_estimates[i];
                    predVal << "R: " << p;
                    rectangle(rgbMat, Point(30, 120), Point(p*300.0+30, 130), Scalar(0, 255, 0), CV_FILLED);
                    putText(rgbMat, predVal.str(), Point(30, 110), CV_FONT_HERSHEY_PLAIN, 1, Scalar(255, 255, 255));
                break;
                case 3:
                    p = prob_estimates[i];
                    predVal << "C: " << p;
                    rectangle(rgbMat, Point(30, 80), Point(p*300.0+30, 90), Scalar(0, 0, 255), CV_FILLED);
                    putText(rgbMat, predVal.str(), Point(30, 70), CV_FONT_HERSHEY_PLAIN, 1, Scalar(255, 255, 255));
                    break;
            }
        }
    }
}

void rgbCallback(uint8_t* rgb) {
    // Get the data from the Kinect
    memcpy(rgbMat.data, rgb, 1280*1024*3*sizeof(uint8_t));
    cvtColor(rgbMat, rgbMat, CV_BGR2RGB);

    if ((faceTracker->track(rgbMat))==0) { // Successfully found face
        faceTracker->drawEyeBoxes(rgbMat, false);

        faceTracker->getCroppedEyes(leftEye, rightEye);

        double* vals = svm->predict(leftEye, rightEye);
        updateDrawnPredictions(vals);

        update = true;

    } 
}

void depthCallback(uint16_t* depth) {
    memcpy(depthMat.data, depth, 640*480*sizeof(uint8_t));

}


void* kinectRun(void* none) {
    // This is a blocking function, but we can set kinect->die to 1 to stop
    // pulling frames
    kinect->start();

    return 0;
}

int main(int argc, const char * argv[])
{
    // Set up FaceTracker
    faceTracker = new FaceTrackerWrapper();

    // Set up SVM
    svm = new SVMWrapper("../model/svm_trained.model");

    // Set up Kinect
    kinect = new KinectFreenect();
    kinect->setRGBCallback(rgbCallback);
    kinect->setDepthCallback(depthCallback);

    // Spawn thread to pull images from the Kinect
    cout << "Starting Kinect..." << endl;
    pthread_t kinectThread;
    pthread_create(&kinectThread, NULL, kinectRun, NULL);

    // Main thread
    while (1) {
        if (update) {
            imshow("RGB", rgbMat);
            update = false;
        }
        char k = cvWaitKey(100);
        if( k == 27 ) {
            break;
        }
    }

    if ((kinect->stop()) == 0) {
        cout << "Successfuly stopped Kinect." << endl;        
    }

    pthread_join(kinectThread, NULL);

    cout << "Done!" << endl;

    return 0;
}
