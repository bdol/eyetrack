//
//  TableObjectDetector.h
//  TableTop
//
//  Created by Brian Dolhansky on 5/9/13.
//  Copyright (c) 2013 Brian Dolhansky. All rights reserved.
//

#ifndef __TableTop__TableObjectDetector__
#define __TableTop__TableObjectDetector__

#include <iostream>
#include <opencv2/opencv.hpp>
#include <vector>
#include "KinectCalibParams.h"
#include "Box3D.h"

using namespace cv;
using namespace std;

class TableObjectDetector
{
public:
    TableObjectDetector();
    ~TableObjectDetector();
    
    Mat fitPlane(Mat depthWorld);
    void drawTablePlane(Mat img, Mat* plane, KinectCalibParams* calib);
    Mat findObjects(Mat depthWorld, Mat plane);
    Mat clusterObjects(Mat P, int K);
    void drawObjectPoints(Mat img, Mat P, Mat L, KinectCalibParams* calib);
    vector<Box3d*> getHulls(Mat P, Mat L, Mat plane);
    
private:
    Mat getClosestPoints(Mat depthWorld, double depthLimit);
    Mat getPlanePoints(Mat normal, double rho, Mat X, Mat Y);
    Mat pointPlaneDist(Mat depthWorld, Mat plane);
    Mat determinePlaneRotation(Mat normal);
};

#endif /* defined(__TableTop__TableObjectDetector__) */
