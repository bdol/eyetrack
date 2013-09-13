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
#include <cmath>
#include <opencv2/opencv.hpp>
#include <vector>
#include "KinectCalibParams.h"
#include "Box3D.h"
#include "Common.h"

using namespace cv;
using namespace std;

class TableObjectDetector
{
public:
    TableObjectDetector();
    ~TableObjectDetector();
    
    Mat fitPlane(const Mat depthWorld);
    Mat fitPlaneRANSAC(const Mat depthWorld);
    void drawTablePlane(Mat img, Mat* plane, KinectCalibParams* calib);
    Mat findObjects(Mat depthWorld, Mat plane);
    Mat clusterObjects(Mat P, int K, bool removeOutliers);
    Mat clusterObjectsHierarchical(Mat P, int max_clusters);
    void drawObjectPoints(Mat img, const Mat P, const Mat L, KinectCalibParams* calib);
    void draw3DPointsIn2D(Mat img, const Mat P, KinectCalibParams* calib);
    vector<Box3d*> getHulls(const Mat P, const Mat L, const Mat plane);
    vector<Box3d*> getObjectHulls();
    
private:
    Mat getClosestPoints(Mat depthWorld, double depthLimit);
    Mat getPlanePoints(Mat normal, double rho, Mat X, Mat Y);
    Mat pointPlaneDist(Mat depthWorld, Mat plane);
    Mat determinePlaneRotation(Mat normal);
    vector<Box3d*> objectHulls;
};

#endif /* defined(__TableTop__TableObjectDetector__) */
