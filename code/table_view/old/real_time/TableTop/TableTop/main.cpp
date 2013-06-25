//
//  main.cpp
//  NI_CV_Test
//
//  Created by Brian Dolhansky on 5/7/13.
//  Copyright (c) 2013 Brian Dolhansky. All rights reserved.
//

#include <iostream>
#include <opencv2/opencv.hpp>
#include <opencv2/highgui/highgui.hpp>
#include <opencv/cvaux.h>
#include <opencv2/imgproc/imgproc.hpp>

#include "MutexWrapper.h"
#include "MyFreenectDevice.h"
#include "KinectCalibParams.h"
#include "KinectUtilities.h"
#include "TableObjectDetector.h"

using namespace cv;
using namespace std;

int main(int argc, const char * argv[])
{
//	Mat depthMat(Size(640,480),CV_16UC1);
//	Mat depthf  (Size(640,480),CV_8UC1);
//	Mat rgbMat(Size(640,480),CV_8UC3,Scalar(0));
//	Mat ownMat(Size(640,480),CV_8UC3,Scalar(0));
    
    KinectCalibParams* kinectCalibParams = new KinectCalibParams("/Users/bdol/code/eyetrack/util/calibrate_kinect/calibration-grasp8.yml");

    Mat depthImage = imread("/Users/bdol/code/eyetrack/code/table_view/test_code/images/depth_0.png", CV_LOAD_IMAGE_ANYDEPTH);
    Mat depthInMeters = rawDepthToMeters(depthImage);
    Mat depthWorld = depthToWorld(depthInMeters, kinectCalibParams->getDepthIntrinsics());

    TableObjectDetector* tableObjectDetector = new TableObjectDetector();
    Mat plane = tableObjectDetector->fitPlane(depthWorld);
    
    Mat rgbImage = imread("/Users/bdol/code/eyetrack/code/table_view/test_code/images/rgb_0.png");
    tableObjectDetector->drawTablePlane(rgbImage, &plane, kinectCalibParams);
    namedWindow("Detected Plane");
    imshow("Detected Plane", rgbImage);
    cvWaitKey();
    
    depthImage = imread("/Users/bdol/code/eyetrack/code/table_view/test_code/images/depth_5.png", CV_LOAD_IMAGE_ANYDEPTH);
    depthInMeters = rawDepthToMeters(depthImage);
    depthWorld = depthToWorld(depthInMeters, kinectCalibParams->getDepthIntrinsics());
    rgbImage = imread("/Users/bdol/code/eyetrack/code/table_view/test_code/images/rgb_5.png");

    Mat P = tableObjectDetector->findObjects(depthWorld, plane);
    Mat L = tableObjectDetector->clusterObjects(P, 3);
    tableObjectDetector->drawObjectPoints(rgbImage, P, L, kinectCalibParams);
    namedWindow("Detected Objects");
    imshow("Detected Objects", rgbImage);
    cvWaitKey();
    
    rgbImage = imread("/Users/bdol/code/eyetrack/code/table_view/test_code/images/rgb_5.png");
    vector<Box3d*> B = tableObjectDetector->getHulls(P, L, plane);
//    for (int i=0; i<B.size(); i++) {
//        Box3d* Bi = B.at(i);
//        Bi->draw2D(rgbImage, kinectCalibParams);
//    }
    B.at(0)->draw2D(rgbImage, kinectCalibParams, Scalar(255, 0, 0));
    B.at(1)->draw2D(rgbImage, kinectCalibParams, Scalar(0, 255, 0));
    B.at(2)->draw2D(rgbImage, kinectCalibParams, Scalar(0, 0, 255));
    namedWindow("Object Hulls");
    imshow("Object Hulls", rgbImage);
    cvWaitKey();
    

// Real time:
//    bool die(false);
//	int i_snap(0),iter(0);
//    string filename("/Users/bdol/Desktop/plane_test/");
//	string suffix(".png");
//    namedWindow("rgb",CV_WINDOW_AUTOSIZE);
//	namedWindow("depth",CV_WINDOW_AUTOSIZE);
//    
//    Freenect::Freenect freenect;
//    MyFreenectDevice& device = freenect.createDevice<MyFreenectDevice>(0);
//    
//    device.startVideo();
//	device.startDepth();
//    
//    while (!die) {
//    	device.getVideo(rgbMat);
//    	device.getDepth(depthMat);
//        cv::imshow("rgb", rgbMat);
//    	depthMat.convertTo(depthf, CV_8UC1, 255.0/2048.0);
//        cv::imshow("depth",depthf);
//		char k = cvWaitKey(5);
//        
//		if( k == 27 ){
//		    cvDestroyWindow("rgb");
//		    cvDestroyWindow("depth");
//			break;
//		}
//		if( k == 32 ) {
//			std::ostringstream fileRGB, fileDepth;
//			fileRGB << filename << "rgb_" << i_snap << suffix;
//            fileDepth << filename << "depth_" << i_snap << suffix;
//			cv::imwrite(fileRGB.str(),rgbMat);
//            cv::imwrite(fileDepth.str(),depthMat);
//			i_snap++;
//		}
//		iter++;
//        
//    }
//    
//    device.stopVideo();
//	device.stopDepth();
    
    return 0;
}

