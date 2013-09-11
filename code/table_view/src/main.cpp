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

#include <socket/Socket.h>
#include <eye_gaze_lib/EyeGaze.h>

using namespace cv;
using namespace std;

double rgbScale = 1.5;

// Eye gaze utilities
EyeGaze* eyeGaze = new EyeGaze();
int gazeX = 0;
int gazeY = 0;
bool validGaze = false;

// Debug options
bool showEyeTarget = false; // press the e key to toggle on/off
bool showObjectHulls = false;

void mouseEvent(int evt, int x, int y, int flags, void* param){
    if(evt==CV_EVENT_LBUTTONDOWN){
        gazeX = x;
        gazeY = y;
        validGaze = true;
    }
}

void messageReceived(char* buff) {
    string message(buff);
    eyeGaze->parseGazeMessage(message, gazeX, gazeY);
    if (gazeX > 0 && gazeY > 0) {
        validGaze = true;
    } else {

    }
}

int main(int argc, const char * argv[])
{
    // Wait for connection
    Socket* mySocket = new Socket();
    cout << "Listening for connections from eye view program..." << endl;
    mySocket->startServer(messageReceived);

    // Calibrate the eye tracker for use on this screen
    //eyeGaze->calibrate();

    // Set up the Kinect
    KinectCalibParams* kinectCalibParams = new KinectCalibParams("/Users/bdol/code/eyetrack/util/calibrate_kinect/grasp8.yml");
    TableObjectDetector* tableObjectDetector = new TableObjectDetector();
    Mat plane;
    
    // Real time:
	Mat depthMat(Size(640,480),CV_16UC1);
	Mat depthf  (Size(640,480),CV_8UC1);
	Mat rgbMat(Size(640,480),CV_8UC3,Scalar(0));
    Mat rgbBig;
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
    namedWindow("rgb", CV_WINDOW_AUTOSIZE);
    cvMoveWindow("rgb", 150, 0);
    cvSetMouseCallback("rgb", mouseEvent, 0);

    while (!die) {
    	device.getVideo(rgbMat);
    	device.getDepth(depthMat);

        resize(rgbMat, rgbBig, Size(int(rgbMat.cols*rgbScale), int(rgbMat.rows*rgbScale)), 0, 0, INTER_LINEAR);
        // Draw the eye target if the option is on
        if (validGaze && showEyeTarget) {
            circle(rgbBig, Point(gazeX, gazeY), 5, Scalar(255, 255, 255), -1);
            circle(rgbBig, Point(gazeX, gazeY), 50, Scalar(0, 255, 0), 3);
            circle(rgbBig, Point(gazeX, gazeY), 100, Scalar(0, 0, 255), 3);
        }


    	depthMat.convertTo(depthf, CV_8UC1, 255.0/2048.0);
        cv::imshow("depth",depthf);
		char k = cvWaitKey(5);

        if (k==101) { // e key, toggle eye target on and off
            showEyeTarget = !showEyeTarget;
        }
        
        if (k==112) { // p key, detect plane
            Mat depthInMeters = rawDepthToMeters(depthMat);
            Mat depthWorld = depthToWorld(depthInMeters, kinectCalibParams->getDepthIntrinsics());
            plane = tableObjectDetector->fitPlaneRANSAC(depthWorld);
            cout << plane << endl;
        }
        if (k==111) { // o key, detect 3 objects
            Mat depthInMeters = rawDepthToMeters(depthMat);
            Mat depthWorld = depthToWorld(depthInMeters, kinectCalibParams->getDepthIntrinsics());
            Mat P = tableObjectDetector->findObjects(depthWorld, plane);
            Mat rgbImageHulls; rgbBig.copyTo(rgbImageHulls);
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
                    
                    //B.at(i)->draw2D(rgbBig, kinectCalibParams, colors[cidx]);
                }
                
                Mat rgbImagePoints; rgbMat.copyTo(rgbImagePoints);
                tableObjectDetector->drawObjectPoints(rgbImagePoints, P, L, kinectCalibParams);
                namedWindow("Detected Objects");
                imshow("Detected Objects", rgbImagePoints);

            }
            
            imshow("rgb", rgbImageHulls);
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
        if ( k == 104 ) { // h key, toggle showing object hulls
            showObjectHulls = !showObjectHulls;
        }


		iter++;
        
        if (showObjectHulls) {
            vector<Box3d*> B = tableObjectDetector->getObjectHulls();
            for (int i=0; i<B.size(); i++) {
                cout << B.at(i) << endl;
                B.at(i)->draw2D(rgbBig, kinectCalibParams, rgbScale, colors[1]);
            }
            stringstream otext;
            otext << "Number objects detected: " << B.size();
            putText(rgbBig, otext.str(), Point(30, 30), CV_FONT_HERSHEY_PLAIN, 1, Scalar(255, 255, 255));
        }    

        imshow("rgb", rgbBig);

    }
    
    device.stopVideo();
	device.stopDepth();
    
    return 0;
}

