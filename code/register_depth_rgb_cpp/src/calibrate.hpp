/*
 * calibrate.hpp
 *
 *  Created on: Jun 19, 2013
 *      Author: varsha
 */

#ifndef CALIBRATE_HPP_
#define CALIBRATE_HPP_

#include <iostream>
#include <string>
#include <fstream>
#include <opencv2/opencv.hpp>

// RGB camera params
double rgb_cam_cx=6.29640747e+002; double rgb_cam_cy=5.17733276e+002;
double rgb_cam_fx=1.05771448e+003; double rgb_cam_fy=1.06197778e+003;

// Depth camera params
double depth_cam_cx=3.20674194e+002; double depth_cam_cy=2.38202423e+002;
double depth_cam_fx=5.93567322e+002; double depth_cam_fy=5.96097961e+002;

// Stereo calibration params
// In mts
double Trans[3] = {1.9985242312092553e-02, -7.4423738761617583e-04, -1.0916736334336222e-02};
double Rot[3][3] = { 9.9984628826577793e-01, -1.4779096108364480e-03, 1.7470421412464927e-02,
             1.2635359098409581e-03, 9.9992385683542895e-01,  1.2275341476520762e-02,
             -1.7487233004436643e-02, -1.2251380107679535e-02, 9.9977202419716948e-01 };


#endif /* CALIBRATE_HPP_ */
