//
//  Box3D.cpp
//  TableTop
//
//  Created by Brian Dolhansky on 5/10/13.
//  Copyright (c) 2013 Brian Dolhansky. All rights reserved.
//

#include <table_view_lib/Box3D.h>

Box3d::Box3d(Mat P) {
    this->P = P;
}

void Box3d::draw2D(Mat img, KinectCalibParams *calib, double scale, Scalar color) {
    Mat Pt; transpose(this->P, Pt);
    Mat K = calib->getRGBIntrinsics();
    Mat R; (calib->getR()).copyTo(R); transpose(R, R);
    Mat T = calib->getT();
 
    // Apply extrinsics
    cout << R.rows << " " << R.cols << " " << P.rows << " " << P.cols << endl;
    Mat P = R*Pt;
    for (int i=0; i<P.cols; i++) {
        P.col(i) = P.col(i)-T;
    }

    Mat Pim = K*P;
    vector<Point> pts;
    for (int i=0; i<Pim.cols; i++) {
        Point p(scale*Pim.col(i).at<double>(0)/Pim.col(i).at<double>(2),
                scale*Pim.col(i).at<double>(1)/Pim.col(i).at<double>(2));
        pts.push_back(p);
    }
    
    // Bottom square
    line(img, pts.at(0), pts.at(1), color);
    line(img, pts.at(1), pts.at(2), color);
    line(img, pts.at(2), pts.at(3), color);
    line(img, pts.at(3), pts.at(0), color);
    // Sides
    line(img, pts.at(0), pts.at(4), color);
    line(img, pts.at(1), pts.at(5), color);
    line(img, pts.at(2), pts.at(6), color);
    line(img, pts.at(3), pts.at(7), color);
    // Top square
    line(img, pts.at(5), pts.at(4), color);
    line(img, pts.at(6), pts.at(5), color);
    line(img, pts.at(7), pts.at(6), color);
    line(img, pts.at(4), pts.at(7), color);
}
