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

#include <table_view_lib/MyFreenectDevice.h>
#include <table_view_lib/KinectCalibParams.h>
#include <table_view_lib/KinectUtilities.h>
#include <table_view_lib/TableObjectDetector.h>

using namespace cv;
using namespace std;

int main(int argc, const char * argv[])
{
    KinectCalibParams* kinectCalibParams = new KinectCalibParams("/Users/bdol/code/eyetrack/util/calibrate_kinect/grasp8.yml");
    TableObjectDetector* tableObjectDetector = new TableObjectDetector();
    Mat plane;
    
    // Real time:
	Mat depthMat(Size(640,480),CV_16UC1);
	Mat depthf  (Size(640,480),CV_8UC1);
	Mat rgbMat(Size(640,480),CV_8UC3,Scalar(0));
	Mat ownMat(Size(640,480),CV_8UC3,Scalar(0));
     
    bool die(false);
	int i_snap(0),iter(0);
    string filename("/Users/bdol/Desktop/tableTop0/");
	string suffix(".png");
    namedWindow("rgb",CV_WINDOW_AUTOSIZE);
	namedWindow("depth",CV_WINDOW_AUTOSIZE);
    
    Freenect::Freenect freenect;
    MyFreenectDevice& device = freenect.createDevice<MyFreenectDevice>(0);
    
    device.startVideo();
	device.startDepth();
    
    int num_last_objects = 0;
    vector<Mat> hullCentroids;
    while (!die) {
    	device.getVideo(rgbMat);
    	device.getDepth(depthMat);
        cv::imshow("rgb", rgbMat);
    	depthMat.convertTo(depthf, CV_8UC1, 255.0/2048.0);
        cv::imshow("depth",depthf);
		char k = cvWaitKey(5);
        
        if (k==112) { // p key, detect plane
            Mat depthInMeters = rawDepthToMeters(depthMat);
            Mat depthWorld = depthToWorld(depthInMeters, kinectCalibParams->getDepthIntrinsics());
            plane = tableObjectDetector->fitPlane(depthWorld);

            Mat rgbImage; rgbMat.copyTo(rgbImage);
            tableObjectDetector->drawTablePlane(rgbImage, &plane, kinectCalibParams);
            namedWindow("Detected Plane");
            imshow("Detected Plane", rgbImage);
            
        }
        if (k==111) { // o key, detect 3 objects
            Mat depthInMeters = rawDepthToMeters(depthMat);
            Mat depthWorld = depthToWorld(depthInMeters, kinectCalibParams->getDepthIntrinsics());
            Mat P = tableObjectDetector->findObjects(depthWorld, plane);
            Mat rgbImageHulls; rgbMat.copyTo(rgbImageHulls);
            double lmax = -1;
            if (!P.empty()) {
                Mat L = tableObjectDetector->clusterObjectsHierarchical(P);
                minMaxIdx(L, NULL, &lmax);
                vector<Box3d*> B = tableObjectDetector->getHulls(P, L, plane);
                
                // Cluster persistence
                if (lmax+1!=num_last_objects) {
                    num_last_objects = lmax+1;
                    // Recalculate colors
                    hullCentroids.clear();
                    
                    for (int i=0; i<B.size(); i++) {
                        Mat B_centroid;
                        reduce(B.at(i)->P, B_centroid, 0, CV_REDUCE_AVG);
                        hullCentroids.push_back(B_centroid);
                    }
                }
                
                for (int i=0; i<B.size(); i++) {
                    int cidx = 7;
                    double minDist = 99999;
                    Mat B_centroid;
                    reduce(B.at(i)->P, B_centroid, 0, CV_REDUCE_AVG);
                    
                    // Find closest hull fromlast step
                    for (int j=0; j<hullCentroids.size(); j++) {
                        double dx = hullCentroids.at(j).at<double>(0)-B_centroid.at<double>(0);
                        double dy = hullCentroids.at(j).at<double>(1)-B_centroid.at<double>(1);
                        double dz = hullCentroids.at(j).at<double>(2)-B_centroid.at<double>(2);
                        double dist = sqrt(dx*dx+dy*dy+dz*dz);
                        if (dist<minDist) {
                            minDist = dist;
                            cidx = j;
                        }
                    }
                    hullCentroids.at(cidx) = B_centroid;
                    
                    B.at(i)->draw2D(rgbImageHulls, kinectCalibParams, colors[cidx]);
                }
                

            }
            
            stringstream otext;
            otext << "Number objects detected: " << lmax+1;
            putText(rgbImageHulls, otext.str(), Point(30, 30), CV_FONT_HERSHEY_PLAIN, 1, Scalar(255, 255, 255));
            imshow("Object Hulls", rgbImageHulls);
            
//            Mat rgbImagePoints; rgbMat.copyTo(rgbImagePoints);
//            tableObjectDetector->drawObjectPoints(rgbImagePoints, P, L, kinectCalibParams);
//            namedWindow("Detected Objects");
//            imshow("Detected Objects", rgbImagePoints);
            
            
            

        }
        
		if( k == 27 ){ // Esc key, quit
		    cvDestroyWindow("rgb");
		    cvDestroyWindow("depth");
            cvDestroyWindow("Detected Plane");
			break;
		}
		if( k == 32 ) { // Space key, take RGB and depth images
			std::ostringstream fileRGB, fileDepth;
			fileRGB << filename << "rgb_" << i_snap << suffix;
            fileDepth << filename << "depth_" << i_snap << suffix;
			cv::imwrite(fileRGB.str(),rgbMat);
            cv::imwrite(fileDepth.str(),depthMat);
			i_snap++;
		}
		iter++;
        
    }
    
    device.stopVideo();
	device.stopDepth();
    
    return 0;
}

