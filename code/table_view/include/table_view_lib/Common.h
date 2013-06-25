//
//  Common.h
//  TableTopDebug
//
//  Created by Brian Dolhansky on 6/6/13.
//  Copyright (c) 2013 Brian Dolhansky. All rights reserved.
//

#ifndef TableTopDebug_Common_h
#define TableTopDebug_Common_h
#include <opencv2/opencv.hpp>

using namespace cv;

const Scalar blue = Scalar(255, 0, 0);
const Scalar green = Scalar(0, 255, 0);
const Scalar red = Scalar(0, 0, 255);
const Scalar pink = Scalar(255, 0, 255);
const Scalar cyan = Scalar(255, 255, 0);
const Scalar yellow = Scalar(0, 255, 255);
const Scalar black = Scalar(0, 0, 0);
const Scalar white = Scalar(255, 255, 255);
const Scalar colors[] = {blue, green, red, pink, cyan, yellow, black, white};

const Vec3b blue_Vec3b = Vec3b(255, 0, 0);
const Vec3b green_Vec3b = Vec3b(0, 255, 0);
const Vec3b red_Vec3b = Vec3b(0, 0, 255);
const Vec3b pink_Vec3b = Vec3b(255, 0, 255);
const Vec3b cyan_Vec3b = Vec3b(255, 0, 255);
const Vec3b yellow_Vec3b = Vec3b(255, 0, 255);
const Vec3b black_Vec3b = Vec3b(0, 0, 0);
const Vec3b white_Vec3b = Vec3b(255, 255, 255);
const Vec3b colors_Vec3b[] = {blue_Vec3b, green_Vec3b, red_Vec3b, pink_Vec3b, cyan_Vec3b, yellow_Vec3b, black_Vec3b, white_Vec3b};

#endif
