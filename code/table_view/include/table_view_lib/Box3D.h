//
//  Box3D.h
//  TableTop
//
//  Created by Brian Dolhansky on 5/10/13.
//  Copyright (c) 2013 Brian Dolhansky. All rights reserved.
//

#ifndef __TableTop__Box3D__
#define __TableTop__Box3D__

#include <iostream>
#include <opencv2/opencv.hpp>
#include "KinectCalibParams.h"

using namespace cv;
class Box3d
{
public:
    Box3d(Mat P);
    void draw2D(Mat img, KinectCalibParams* calib, double scale, Scalar color);
    Mat P;
    Point get2DCentroid(KinectCalibParams *calib, double scale);
    
private:

};

#endif /* defined(__TableTop__Box3D__) */
