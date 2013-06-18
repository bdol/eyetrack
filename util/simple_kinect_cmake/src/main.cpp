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

#include <opencv2/opencv.hpp>
#include <opencv2/highgui/highgui.hpp>
#include <opencv/cvaux.h>
#include <opencv2/imgproc/imgproc.hpp>
#include "MyFreenectDevice.h"

using namespace cv;
using namespace std;

int main(int argc, const char * argv[])
{    
    Freenect::Freenect freenect;
    MyFreenectDevice& device = freenect.createDevice<MyFreenectDevice>(0);
    
    Mat depthMat(Size(640,480),CV_16UC1);
	Mat depthf  (Size(640,480),CV_8UC1);
	Mat rgbMat(Size(640,480),CV_8UC3,Scalar(0));
    
    bool die(false);
    
    namedWindow("rgb",CV_WINDOW_AUTOSIZE);
	namedWindow("depth",CV_WINDOW_AUTOSIZE);
    
    device.startVideo();
	device.startDepth();
    
    while (!die) {
    	device.getVideo(rgbMat);
    	device.getDepth(depthMat);
        cv::imshow("rgb", rgbMat);
    	depthMat.convertTo(depthf, CV_8UC1, 255.0/2048.0);
        cv::imshow("depth",depthf);
		char k = cvWaitKey(5);
        
		if(k == 27){ // Esc key, quit, don't accidentally quit while recording
		    cvDestroyWindow("rgb");
		    cvDestroyWindow("depth");
            cvDestroyWindow("Detected Plane");
			break;
		}
    }
    
    device.stopVideo();
	device.stopDepth();
    
    
    return 0;
}
