#ifndef __FaceTrackerWrapper__
#define __FaceTrackerWrapper__

#include <FaceTracker/Tracker.h>
#include <opencv/highgui.h>
#include <iostream>
#include <fstream>
#include <string>

class FaceTrackerWrapper
{
public:
    FaceTrackerWrapper();
    int track(cv::Mat &queryIm);
    int drawEyeBoxes(cv::Mat &queryIm, bool flip);
    int getCroppedEyes(cv::Mat &leftEye, cv::Mat &rightEye);

private:
    bool failed;

    std::vector<int> wSize1;
    std::vector<int> wSize2;
    int nIter;
    double clamp, fTol;
    int fpd;
    bool fcheck;

    FACETRACKER::Tracker* model;
    cv::Mat tri;
    cv::Mat con;

    cv::Mat frame, gray, im;

    cv::Mat leftEyeNorm, rightEyeNorm;

    int updateBoundingBoxes();
    double bb_width;
    double bb_height;
    cv::Point l_centroid, r_centroid;
    cv::Point lb1, lb2, rb1, rb2;

    int cropEyes(cv::Mat &queryIm);
};

#endif
