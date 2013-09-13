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
#include <table_view_lib/TableObject.h>

#include <socket/Socket.h>
#include <eye_gaze_lib/EyeGaze.h>

using namespace cv;
using namespace std;

double rgbScale = 1.5;
double objDetectDist = 100;

KinectCalibParams* kinectCalibParams;
TableObjectDetector* tableObjectDetector;
vector< TableObject* > tableObjects;
Mat rgbMat(Size(640,480),CV_8UC3,Scalar(0));

// Eye gaze utilities
EyeGaze* eyeGaze = new EyeGaze();
int gazeX = 0;
int gazeY = 0;
bool validGaze = false;

// Debug options
bool showEyeTarget = false; // press the e key to toggle on/off
bool showObjectHulls = false; // press the h key to toggle on/off
bool showEyeObjDist = false; // press the d key to toggle on/off
bool showGazeObject = false; // press the g key to toggle on/off
bool showObjectNames = true; // press the n key to toggle on/off

// Naming objects flag
bool objectsSet = false;
Box3d* objectHullInGaze = NULL;
Box3d* locatedObject = NULL;
int highlightObjectFlashesLeft = -1;
int highlightedObjectTimer = -1;

void mouseEvent(int evt, int x, int y, int flags, void* param){
    if(evt==CV_EVENT_LBUTTONDOWN){
        gazeX = x;
        gazeY = y;
        validGaze = true;
    }
}

void setObjects(Mat rgb) {
    tableObjects.clear();
    objectsSet = false;

    vector<Box3d*> B = tableObjectDetector->getObjectHulls();
    for (int i=0; i<B.size(); i++) {
        TableObject* obj = new TableObject();

        vector<Point> pts = B.at(i)->get2DPoints(kinectCalibParams);
        Rect boundRect = boundingRect(pts);
        Mat objIm = rgb(boundRect);
        obj->storeHistogram(objIm);
     
        tableObjects.push_back(obj);
    }

    objectsSet = true;

}

// Response to the user saying - This is an X.
void nameObject(string message, Mat rgb) {
    if (!objectsSet) {
        cout << "Objects not set! Press the s key when the correct number of objects have been detected." << endl;
        return;
    }

    if (objectHullInGaze == NULL) {
        cout << "No object being looked at!" << endl;
        return;
    }

    // First parse the message
    int pos = message.find(":", 0);
    string name = message.substr(pos+1, message.length()-pos);

    vector<Point> pts = objectHullInGaze->get2DPoints(kinectCalibParams);
    Rect boundRect = boundingRect(pts);
    Mat objIm = rgb(boundRect);

    float minDist = 9999999; int closestObjIdx = -1;
    for (int i=0; i<tableObjects.size(); i++) {
        float d = tableObjects.at(i)->getHistogramDistance(objIm);
        if (d < minDist) {
            minDist = d;
            closestObjIdx = i;
        }
    }

    tableObjects.at(closestObjIdx)->setName(name);

}

// Response to the user asking - What am I looking at?
void directObjectQuery() {
    if (objectHullInGaze == NULL) {
        cout << "You are not looking at anything!" << endl;
        return;
    }

    if (!objectsSet) {
        cout << "First name the objects!" << endl;
    }

    vector<Point> pts = objectHullInGaze->get2DPoints(kinectCalibParams);
    Rect boundRect = boundingRect(pts);
    Mat objIm = rgbMat(boundRect);
    float minDist = 99999; int closestObjIdx = -1;

    for (int i=0; i<3; i++) {
        for (int j=0; j<tableObjects.size(); j++) {
            float d = tableObjects.at(j)->getHistogramDistance(objIm);
            if (d < minDist) {
                minDist = d;
                closestObjIdx = j;
            }
        }
    }

    if (closestObjIdx >= 0) {
        string objName = tableObjects.at(closestObjIdx)->getName();
        cout << "You're looking at a(n) " << objName << "." << endl;
    } else {
        cout << "I'm not sure what you're looking at." << endl;
    }
}

// Response to the user asking - Where is the X?
void indirectObjectQuery(string message) {
    if (!objectsSet) {
        cout << "First name the objects!" << endl;
    }

    int pos = message.find(":", 0);
    string objName = message.substr(pos+1, message.length()-pos);

    TableObject* obj = NULL;
    for (int i=0; i<3; i++) {
        if (tableObjects.at(i)->getName().compare(objName) == 0) {
            obj = tableObjects.at(i);
        }
    }

    if (obj == NULL) {
        cout << "I don't see a(n) " << objName << "." << endl;
        return;
    }
    
    vector<Box3d*> B = tableObjectDetector->getObjectHulls();
    if (B.size() == tableObjects.size()) {
        float minDist = 99999; int closestObjIdx = -1;
        for (int i=0; i<3; i++) {
            vector<Point> pts = B.at(i)->get2DPoints(kinectCalibParams);
            Rect boundRect = boundingRect(pts);
            Mat objIm = rgbMat(boundRect);

            float d = obj->getHistogramDistance(objIm);
            if (d < minDist) {
                minDist = d;
                closestObjIdx = i;
            }
        }

        if (closestObjIdx >= 0) {
            locatedObject = B.at(closestObjIdx);
            highlightObjectFlashesLeft = 5;
            highlightedObjectTimer = 50;
        } else {
            cout << "I couldn't find a(n) " << objName << "." << endl;
        }
    }

}

void messageReceived(char* buff) {
    string message(buff);
    if (message.at(0) == 'g') { // eye gaze message
        eyeGaze->parseGazeMessage(message, gazeX, gazeY);
        if (gazeX > 0 && gazeY > 0) {
            validGaze = true;
        }
    } else if (message.at(0) == 'n') { // name object
        nameObject(message, rgbMat);
    } else if (message.at(0) == 'd') { // direct query, "What am I looking at?"
        directObjectQuery();
    } else if (message.at(0) == 'i') { // indirect query, "Where is the X?"
        indirectObjectQuery(message);
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
    kinectCalibParams = new KinectCalibParams("/Users/bdol/code/eyetrack/util/calibrate_kinect/grasp8.yml");
    tableObjectDetector = new TableObjectDetector();
    Mat plane;
    
    // Real time:
	Mat depthMat(Size(640,480),CV_16UC1);
	Mat depthf  (Size(640,480),CV_8UC1);
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
        }
        if (k==111) { // o key, detect 3 objects
            Mat depthInMeters = rawDepthToMeters(depthMat);
            Mat depthWorld = depthToWorld(depthInMeters, kinectCalibParams->getDepthIntrinsics());
            Mat P = tableObjectDetector->findObjects(depthWorld, plane);
            Mat rgbImageHulls; rgbBig.copyTo(rgbImageHulls);
            double lmax = -1;
            if (!P.empty()) {
                //Mat L = tableObjectDetector->clusterObjectsHierarchical(P, 3);
                Mat L = tableObjectDetector->clusterObjects(P, 3, true);
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
        if ( k == 100 ) { // d key, toggle showing distance from eye target to object centroids
            showEyeObjDist = !showEyeObjDist;
        }
        if ( k == 103 ) { // g key, toggle showing a hull around the object of focus
            showGazeObject = !showGazeObject;
        }
        if ( k == 115 ) { // s key, set the objects after a correct detection
            setObjects(rgbMat);
        }
        if ( k == 110 ) {
            showObjectNames = !showObjectNames;
        }


        // Determine which object is in the gaze
        objectHullInGaze = NULL;
        vector<Box3d*> B = tableObjectDetector->getObjectHulls();
        double closestDist = 999999999;
        for (int i=0; i<B.size(); i++) {
            Point centroid = B.at(i)->get2DCentroid(kinectCalibParams, rgbScale);
            
            double d = sqrt((gazeX - centroid.x)*(gazeX - centroid.x) + (gazeY - centroid.y)*(gazeY - centroid.y));
            if (d<=objDetectDist) {
                if (d < closestDist) {
                    closestDist = d;
                    objectHullInGaze = B.at(i);
                }
            }
        }
        
        if (showObjectHulls) {
            vector<Box3d*> B = tableObjectDetector->getObjectHulls();
            for (int i=0; i<B.size(); i++) {
                B.at(i)->draw2D(rgbBig, kinectCalibParams, rgbScale, colors[1]);
            }
            stringstream otext;
            otext << "Number objects detected: " << B.size();
            putText(rgbBig, otext.str(), Point(30, 30), CV_FONT_HERSHEY_PLAIN, 1, Scalar(255, 255, 255));
        }

        if (showEyeObjDist) {
            vector<Box3d*> B = tableObjectDetector->getObjectHulls();
            for (int i=0; i<B.size(); i++) {
                Point centroid = B.at(i)->get2DCentroid(kinectCalibParams, rgbScale);
                circle(rgbBig, centroid, 5, Scalar(0, 0, 255), -1);
                
                double d = sqrt((gazeX - centroid.x)*(gazeX - centroid.x) + (gazeY - centroid.y)*(gazeY - centroid.y));
                if (d<=objDetectDist) {
                    line(rgbBig, Point(gazeX, gazeY), centroid, Scalar(0, 255, 0), 2, 8);
                } else {
                    line(rgbBig, Point(gazeX, gazeY), centroid, Scalar(0, 0, 255), 2, 8);
                }
            }

        }

        if (showGazeObject) {
            if (objectHullInGaze != NULL ) {
                objectHullInGaze->draw2D(rgbBig, kinectCalibParams, rgbScale, colors[1]);
            }
        }

        if (showObjectNames) {
            if (objectsSet) {
                vector<Box3d*> B = tableObjectDetector->getObjectHulls();
                
                if (B.size() == tableObjects.size()) {
                    for (int i=0; i<3; i++) {
                        vector<Point> pts = B.at(i)->get2DPoints(kinectCalibParams);
                        Rect boundRect = boundingRect(pts);
                        Mat objIm = rgbMat(boundRect);

                        float minDist = 99999; int closestObjIdx = -1;
                        for (int j=0; j<tableObjects.size(); j++) {
                            float d = tableObjects.at(j)->getHistogramDistance(objIm);
                            if (d < minDist) {
                                minDist = d;
                                closestObjIdx = j;
                            }
                        }

                        if (closestObjIdx >= 0) {
                            putText(rgbBig, tableObjects.at(closestObjIdx)->getName(), Point(boundRect.x*1.5, boundRect.y*1.5), CV_FONT_HERSHEY_PLAIN, 1, Scalar(0, 255, 0));
                        }
                    }
                }

            }

        }

        if (highlightObjectFlashesLeft > 0) {
            if (locatedObject != NULL) {
                if (highlightedObjectTimer > 25) {
                    locatedObject->draw2D(rgbBig, kinectCalibParams, rgbScale, colors[3]);
                }

                highlightedObjectTimer--;
                if (highlightedObjectTimer <= 0) {
                    highlightObjectFlashesLeft--;
                    highlightedObjectTimer = 50;
                }
            }

        }

        imshow("rgb", rgbBig);
		iter++;
    }
    
    device.stopVideo();
	device.stopDepth();
    
    return 0;
}

