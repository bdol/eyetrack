//
//  KinectCalibParams.h
//  TableTop
//
//  Created by Brian Dolhansky on 5/9/13.
//  Copyright (c) 2013 Brian Dolhansky. All rights reserved.
//

#ifndef __TableTop__KinectCalibParams__
#define __TableTop__KinectCalibParams__

#include <iostream>
#include <opencv2/opencv.hpp>

using namespace std;
using namespace cv;
class KinectCalibParams
{
public:
    KinectCalibParams(string);
    ~KinectCalibParams();
    Mat getRGBIntrinsics();
    Mat getRGBDistortion();
    Mat getDepthIntrinsics();
    Mat getDepthDistortion();
    Mat getR();
    Mat getT();
  
private:
    Mat rgbIntrinsics, rgbDistortion;
    Mat depthIntrinsics, depthDistortion;
    Mat R, T;
};

#endif /* defined(__TableTop__KinectCalibParams__) */
