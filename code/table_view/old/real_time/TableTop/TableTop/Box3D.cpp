//
//  Box3D.cpp
//  TableTop
//
//  Created by Brian Dolhansky on 5/10/13.
//  Copyright (c) 2013 Brian Dolhansky. All rights reserved.
//

#include "Box3D.h"

Box3d::Box3d(Mat P) {
    this->P = P;
}

void Box3d::draw2D(Mat img, KinectCalibParams *calib, Scalar color) {
    Mat Pt; transpose(P, Pt);
    
    
    Mat K = calib->getRGBIntrinsics();
    Mat R = calib->getR();
    transpose(R, R);
    Mat T = calib->getT();
 
    // Apply extrinsics
    P = R*Pt;
    for (int i=0; i<P.cols; i++) {
        P.col(i) = P.col(i)-T;
    }
    Mat Pim = K*P;
//    cout << Pim << endl;
    vector<Point> pts;
    for (int i=0; i<Pim.cols; i++) {
        Point p(Pim.col(i).at<double>(0)/Pim.col(i).at<double>(2),
                Pim.col(i).at<double>(1)/Pim.col(i).at<double>(2));
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