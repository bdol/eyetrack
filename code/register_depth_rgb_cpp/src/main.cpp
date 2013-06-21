/* 
 * File:   main.cpp
 * Author: varsha
 *
 * Created on June 18, 2013, 9:26 AM
 */

#include "calibrate.hpp"
//#include <XnCppWrapper.h>

using namespace std;
using namespace cv;

typedef unsigned char u8;       // guaranteed to be 1 byte
#define IMAGE_XRES 1280
#define IMAGE_YRES 1024
#define DEPTH_XRES 640
#define DEPTH_YRES 480

void load_rgb_depth_images(Mat &depth_im, Mat &rgb_im, string depth_im_path, string rgb_im_path)
{
	// load depth image
	Mat depth_im_full;
	Mat tempmat(DEPTH_XRES*DEPTH_YRES, 1, CV_16UC1);
	ifstream fin(depth_im_path.c_str(), ios::in|ios::ate);
	int count = 0;
	if(fin.is_open())
	{
		ifstream::pos_type size = fin.tellg();
		fin.seekg(0, ios::beg);
		char *temp = new char[size];
		fin.read(temp, size);
		fin.close();
		ushort hi = 0;
		ushort lo = 0;
		ushort shifted = 0;
		for(long i = 0, j = 0; i<size; i+=2, j++)
		{
			hi = (uchar)(*(temp + i+1));
			lo = (uchar)(*(temp+i));
			shifted = (hi<<8) | lo;
			tempmat.at<ushort>(j,0) = shifted;
		}
		depth_im_full = tempmat.reshape(1,DEPTH_YRES);
		depth_im = depth_im_full(Rect(8, 0, DEPTH_XRES-8, DEPTH_YRES));
//		imwrite("depth_im.png", depth_im);
	}

	// load rgb image
//	Mat rgb_im;
	fin.open(rgb_im_path.c_str(), ios::in|ios::ate);
	if(fin.is_open())
	{
		ifstream::pos_type size = fin.tellg();
		fin.seekg(0, ios::beg);
		char *temp = new char[size];
		fin.read(temp, size);
		fin.close();
		rgb_im = Mat(IMAGE_YRES, IMAGE_XRES, CV_8UC3, temp);
		cvtColor(rgb_im, rgb_im, CV_BGR2RGB);
		//		imshow("RGB", rgb_im);
		//		waitKey(0);
	}
}

/*
 * 
 */
int main(int argc, char** argv) {

	string depth_im_path = "C:/Users/varsha/Documents/ResearchEyetrackCode/eyetrack/code/register_depth_rgb_cpp/images/1006.2.E/DP_2_2.raw";
	string rgb_im_path = "C:/Users/varsha/Documents/ResearchEyetrackCode/eyetrack/code/register_depth_rgb_cpp/images/1006.2.E/IM_2_2.raw";

	Mat depth_im, rgb_im;
	load_rgb_depth_images(depth_im, rgb_im, depth_im_path, rgb_im_path);
//	imshow("rgb", rgb_im); waitKey(0);
	Mat depth_colour(depth_im.rows, depth_im.cols, CV_8UC3);

	double p3d_x, p3d_y, p3d_z;
	double p3d_rgb_x, p3d_rgb_y, p3d_rgb_z;
	double p2d_rgb_x, p2d_rgb_y;
	cout<<depth_im.cols<<":"<<depth_im.rows;
	cout<<endl<<depth_colour.cols<<":"<<depth_colour.rows;
	cout<<Trans[0]<<","<<Trans[1]<<","<<Trans[2]<<endl;
//	cout<<depth_im.at<ushort>()
	for(long y_d = 0; y_d<depth_im.rows; y_d++)
	{
		for(long x_d = 0; x_d<depth_im.cols; x_d++)
		{
			// project depth pixels into 3d, but remember to divide by 1000 to convert mm to meters
			p3d_x = ((x_d - depth_cam_cx) * depth_im.at<ushort>(y_d, x_d)) / (1000*depth_cam_fx);
			p3d_y = ((y_d - depth_cam_cy) * depth_im.at<ushort>(y_d, x_d)) / (1000*depth_cam_fy);
			p3d_z = (double)depth_im.at<ushort>(y_d, x_d)/1000;

			// change FoR/viewpoint from depth to rgb
			p3d_rgb_x = Rot[0][0]*p3d_x + Rot[0][1]*p3d_y + Rot[0][2]*p3d_z + Trans[0];
			p3d_rgb_y = Rot[1][0]*p3d_x + Rot[1][1]*p3d_y + Rot[1][2]*p3d_z + Trans[1];
			p3d_rgb_z = Rot[2][0]*p3d_x + Rot[2][1]*p3d_y + Rot[2][2]*p3d_z + Trans[2];

			// reproject 3d rgb to rgb pixels
			// (y_d, x_d) in depth --> (P2D_rgb_y, P2D_rgb_x) in rgb
			p2d_rgb_x = round((p3d_rgb_x * rgb_cam_fx / p3d_rgb_z) + rgb_cam_cx);
			p2d_rgb_y = round((p3d_rgb_y * rgb_cam_fy / p3d_rgb_z) + rgb_cam_cy);

			if(x_d==1&&y_d==1)
				cout<<p2d_rgb_x<<","<<p2d_rgb_y<<endl;

			// colour the depth image
			if(p2d_rgb_x>=0 && p2d_rgb_x<rgb_im.cols && p2d_rgb_y>=0 && p2d_rgb_y<rgb_im.rows)
			{
//				cout<<p2d_rgb_y<<","<<p2d_rgb_x<<endl;
				depth_colour.at<Vec3b>(y_d, x_d) = rgb_im.at<Vec3b>(p2d_rgb_y, p2d_rgb_x);
			}
		}
	}

////	imshow("depth colour", depth_colour); waitKey(0);
	imwrite("depth_im.png", depth_colour);
	return 0;
}

