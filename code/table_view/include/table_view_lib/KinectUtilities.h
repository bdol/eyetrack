#ifndef __TableTop__KinectUtilities__
#define __TableTop__KinectUtilities__

#include <opencv2/opencv.hpp>
#include <iostream>

extern cv::Mat rawDepthToMeters(cv::Mat rawDepth);
extern cv::Mat depthToWorld(cv::Mat depth, cv::Mat depthIntrinsics);

#endif
