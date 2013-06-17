//============================================================================
// Name        : face_and_head.cpp
// Author      : varsha
// Version     :
// Copyright   : 
// Description : Hello World in C++, Ansi-style
//============================================================================

// INCLUDES -------------------------------------------------------------------------
#include <iostream>
#include <XnOS.h>
#include <XnCppWrapper.h>
#include <XnCodecIDs.h>
#include <XnStatus.h>
#include "head_pose.hpp"
#include "face_tracker_eyes_rt.hpp"
#include <opencv2/opencv.hpp>

// DEFINES -------------------------------------------------------------------------
#define NONMINMAX
#define XML_PATH "../data/HighRGB_RegDepth.xml"

using namespace std;
using namespace xn;
using namespace cv;

// GLOBALS -------------------------------------------------------------------------
DepthGenerator depth_gen;
ImageGenerator image_gen;
Context context;
DepthMetaData depth_md;
ImageMetaData image_md;
XnMapOutputMode image_mode;
XnMapOutputMode depth_mode;
float f;
Mat depth_im;
Mat image_im;
Mat left_eye, right_eye;

void init_kinect(){

	std::cout << "initializing kinect... " << endl;

	EnumerationErrors errors;
	XnStatus retstat = context.InitFromXmlFile(XML_PATH, &errors);
	if(retstat == XN_STATUS_OK)
	{
		NodeInfoList nodes;
		context.EnumerateExistingNodes(nodes);
		for (NodeInfoList::Iterator iter = nodes.Begin(); iter!=nodes.End(); iter++)
		{
			switch ((*iter).GetDescription().Type)
			{
				case XN_NODE_TYPE_DEPTH:
					(*iter).GetInstance(depth_gen);
					break;
				case XN_NODE_TYPE_IMAGE:
					(*iter).GetInstance(image_gen);
					break;
			}
		}

		if(!depth_gen.IsValid())
			cout<<"Failed to create depth generator"<<endl;
		else
		{
			depth_gen.GetMapOutputMode(depth_mode);
			cout<<"Depth : Res="<<depth_mode.nXRes<<"x"<<depth_mode.nYRes<<" @fps="<<depth_mode.nFPS<<endl;
		}

		if(!image_gen.IsValid())
			cout<<"Failed to create image generator"<<endl;
		else
		{
			image_gen.GetMapOutputMode(image_mode);
			cout<<"Image : Res="<<image_mode.nXRes<<"x"<<image_mode.nYRes<<" @fps="<<image_mode.nFPS<<endl;
		}
	}
	else
		cout<<"Failed to open kinect device: "<<xnGetStatusString(retstat)<<endl;
}

void init_head_pose()
{
	// load head pose config file and trees
	loadConfig("../config.txt");
	g_Estimate =  new CRForestEstimator();
	if( !g_Estimate->loadForest(g_treepath.c_str(), g_ntrees) ){

		cerr << "could not read forest!" << endl;
		exit(-1);
	}

	// get the focal length in mm (ZPS = zero plane distance)
	depth_gen.GetIntProperty ("ZPD", g_focal_length);
	// get the pixel size in mm ("ZPPS" = pixel size at zero plane)
	depth_gen.GetRealProperty ("ZPPS", g_pixel_size);
	g_pixel_size *= 2.f;
	f = g_focal_length/g_pixel_size;

	g_im3D.create(depth_mode.nYRes, depth_mode.nXRes, CV_32FC3);
//	depth_im.create(depth_mode.nYRes, depth_mode.nXRes, CV_32FC3);
//	image_im.create(image_mode.nYRes, image_mode.nXRes, CV_32FC3);
}


void shutdown_kinect()
{
	cout<<"Shutting down kinect process"<<endl;
	depth_gen.Release();
	image_gen.Release();
	context.Release();
}

void read_frames()
{
	// update all kinect nodes - depth and image
	XnStatus retstat = context.WaitAndUpdateAll();
	if(retstat == XN_STATUS_OK)
	{
		if(depth_gen.IsValid())
		{
			depth_gen.GetMetaData(depth_md);
			int valid_pixels = 0;

			//generate 3D image for head pose
			for(int y = 0; y < g_im3D.rows; y++)
			{
				Vec3f* Mi = g_im3D.ptr<Vec3f>(y);
				for(int x = 0; x < g_im3D.cols; x++)
				{
					float d = (float)depth_md(x,y);

					if ( d < g_max_z && d > 0 )
					{
						valid_pixels++;
						Mi[x][0] = ( float(d * (x - 320)) / f );
						Mi[x][1] = ( float(d * (y - 240)) / f );
						Mi[x][2] = d;
					}
					else
						Mi[x] = 0;
				}
			}
			//this part is to set the camera position, depending on what's in the scene
			if (g_first_rigid ) {

				if( valid_pixels > 50000){ //wait for something to be in the image

					// calculate gravity center
					Vec3f gravity(0,0,0);
					int count = 0;
					for(int y=0;y<g_im3D.rows;++y){
						const Vec3f* Mi = g_im3D.ptr<Vec3f>(y);
						for(int x=0;x<g_im3D.cols;++x){

							if( Mi[x][2] > 0 ) {

								gravity = gravity + Mi[x];
								count++;
							}
						}
					}

					float maxDist = 0;
					if(count > 0) {

						gravity = (1.f/(float)count)*gravity;

						for(int y=0;y<g_im3D.rows;++y){
							const Vec3f* Mi = g_im3D.ptr<Vec3f>(y);
							for(int x=0;x<g_im3D.cols;++x){

								if( Mi[x][2] > 0 ) {

									maxDist = MAX(maxDist,(float)norm( Mi[x]-gravity ));
								}
							}
						}
					}

					g_camera.resetview( math_vector_3f(gravity[0],gravity[1],gravity[2]), maxDist );
					g_camera.rotate_180();
					g_first_rigid = false;
				}
			}
			g_means.clear();
			g_votes.clear();
			g_clusters.clear();

			//do the actual estimation
			g_Estimate->estimate(g_im3D, g_means,g_clusters,g_votes,g_stride,g_maxv,g_prob_th,g_larger_radius_ratio,g_smaller_radius_ratio,false,g_th);
			Mat temp(depth_mode.nYRes, depth_mode.nXRes, CV_16SC1, (void*)depth_gen.GetDepthMap());
			depth_im = temp.clone();

//			if(g_means.size()>0)
//				cout << g_means[0][0] << " " << g_means[0][1] << " " << g_means[0][2] << endl;
//			else
//				cout<<"Estimation = null"<<endl;

		}
		if(image_gen.IsValid())
		{
			image_gen.GetMetaData(image_md);
			Mat temp(image_mode.nYRes, image_mode.nXRes, CV_8UC3, (void*)image_gen.GetRGB24ImageMap());
            image_im = temp.clone();
            //convert color space RGB2BGR
            cvtColor(image_im,image_im,CV_RGB2BGR);
		}
	}
	else
		cout<<"Error reading frames: "<<xnGetStatusString(retstat)<<endl;
}

void idle()
{
	read_frames();
	track_facetracker(image_im, left_eye, right_eye);
	namedWindow("Left eye");
	imshow("Left eye", left_eye);
	namedWindow("Right eye");
	imshow("Right eye", right_eye);

}

int main(int argc, char **argv)
{
	// initialise kinect
	init_kinect();
	init_head_pose();
	init_facetracker();

	cout<<"Press ESC to quit"<<endl;

	// initialize GLUT
	glutInitWindowSize(w, h);
	glutInitDisplayMode(GLUT_DOUBLE | GLUT_RGBA | GLUT_DEPTH);
	glutInit(&argc, argv);

	glutCreateWindow("HeadPoseDemo");
	glutDisplayFunc(draw);
	glutIdleFunc(idle);
	atexit(shutdown_kinect);
	glutMainLoop();

//	do
//	{
//		read_frames();
////		namedWindow("RGB");
////		imshow("RGB", image_im);
////		namedWindow("DEPTH");
////		imshow("DEPTH", depth_im);
//		track_facetracker(image_im, left_eye, right_eye);
//		namedWindow("Left eye");
//		imshow("Left eye", left_eye);
//		namedWindow("Right eye");
//		imshow("Right eye", right_eye);
//
//	}while(waitKey(10)!=27);

	// shutdown kinect
//	shutdown_kinect();
}
