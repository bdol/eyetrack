#include <table_view_lib/KinectUtilities.h>

using namespace cv;
using namespace std;

Mat rawDepthToMeters(Mat rawDepth) {
    Mat depthInMeters(rawDepth.rows, rawDepth.cols, CV_64FC1);
    for (int x=0; x<depthInMeters.cols; x++) {
        for (int y=0; y<depthInMeters.rows; y++) {
            double v = (double)rawDepth.at<unsigned short>(y, x);
            if (v<2047) {
                depthInMeters.at<double>(y, x) = 0.1236*tan(v/2842.5 + 1.1863);
            } else {
                depthInMeters.at<double>(y, x) = -1.0;
            }
        }
    }
    
    return depthInMeters;
}

Mat depthToWorld(Mat depth, Mat depthIntrinsics) {
    double fx = depthIntrinsics.at<double>(0, 0);
    double fy = depthIntrinsics.at<double>(1, 1);
    double cx = depthIntrinsics.at<double>(0, 2);
    double cy = depthIntrinsics.at<double>(1, 2);
    
    Mat depthWorld(depth.rows, depth.cols, CV_64FC3);
    for (int x=0; x<depthWorld.cols; x++) {
        for (int y=0; y<depthWorld.rows; y++) {
            double Zw = depth.at<double>(y, x);
            double Xw, Yw;
            if (Zw!=-1.0) {
                Xw = (x - cx)*Zw/fx;
                Yw = (y - cy)*Zw/fy;
            } else {
                Xw = -1.0;
                Yw = -1.0;
            }
            
            depthWorld.at<Vec3d>(y, x) = Vec3d(Xw, Yw, Zw);
        }
    }
    
    return depthWorld;
}
