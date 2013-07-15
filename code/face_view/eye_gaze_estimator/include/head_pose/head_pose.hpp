/*
// Authors: Gabriele Fanelli, Thibaut Weise, Juergen Gall, BIWI, ETH Zurich
 * // Email: fanelli@vision.ee.ethz.ch

// You may use, copy, reproduce, and distribute this Software for any
// non-commercial purpose, subject to the restrictions of the
// Microsoft Research Shared Source license agreement ("MSR-SSLA").
// Some purposes which can be non-commercial are teaching, academic
// research, public demonstrations and personal experimentation. You
// may also distribute this Software with books or other teaching
// materials, or publish the Software on websites, that are intended
// to teach the use of the Software for academic or other
// non-commercial purposes.
// You may not use or distribute this Software or any derivative works
// in any form for commercial purposes. Examples of commercial
// purposes would be running business operations, licensing, leasing,
// or selling the Software, distributing the Software for use with
// commercial products, using the Software in the creation or use of
// commercial products or any other activity which purpose is to
// procure a commercial gain to you or others.
// If the Software includes source code or data, you may create
// derivative works of such portions of the Software and distribute
// the modified Software for non-commercial purposes, as provided
// herein.

// THE SOFTWARE COMES "AS IS", WITH NO WARRANTIES. THIS MEANS NO
// EXPRESS, IMPLIED OR STATUTORY WARRANTY, INCLUDING WITHOUT
// LIMITATION, WARRANTIES OF MERCHANTABILITY OR FITNESS FOR A
// PARTICULAR PURPOSE, ANY WARRANTY AGAINST INTERFERENCE WITH YOUR
// ENJOYMENT OF THE SOFTWARE OR ANY WARRANTY OF TITLE OR
// NON-INFRINGEMENT. THERE IS NO WARRANTY THAT THIS SOFTWARE WILL
// FULFILL ANY OF YOUR PARTICULAR PURPOSES OR NEEDS. ALSO, YOU MUST
// PASS THIS DISCLAIMER ON WHENEVER YOU DISTRIBUTE THE SOFTWARE OR
// DERIVATIVE WORKS.

// NEITHER MICROSOFT NOR ANY CONTRIBUTOR TO THE SOFTWARE WILL BE
// LIABLE FOR ANY DAMAGES RELATED TO THE SOFTWARE OR THIS MSR-SSLA,
// INCLUDING DIRECT, INDIRECT, SPECIAL, CONSEQUENTIAL OR INCIDENTAL
// DAMAGES, TO THE MAXIMUM EXTENT THE LAW PERMITS, NO MATTER WHAT
// LEGAL THEORY IT IS BASED ON. ALSO, YOU MUST PASS THIS LIMITATION OF
// LIABILITY ON WHENEVER YOU DISTRIBUTE THE SOFTWARE OR DERIVATIVE
// WORKS.

// When using this software, please acknowledge the effort that
// went into development by referencing the paper:
//
// Fanelli G., Weise T., Gall J., Van Gool L., Real Time Head Pose Estimation from Consumer Depth Cameras
// 33rd Annual Symposium of the German Association for Pattern Recognition (DAGM'11), 2011
*/

#ifndef HEAD_POSE_HPP_
#define HEAD_POSE_HPP_

#include <string>
#include <algorithm>
#include <iostream>
#include <vector>
#include <fstream>

#include "CRForestEstimator.h"
#include <common/common.hpp>

#define PATH_SEP "/"

using namespace std;
using namespace cv;

// Path to trees
string g_treepath;
// Number of trees
int g_ntrees;
// Patch width
int g_p_width;
// Patch height
int g_p_height;
//maximum distance form the sensor - used to segment the person
int g_max_z = 0;
//head threshold - to classify a cluster of votes as a head
int g_th = 400;
//threshold for the probability of a patch to belong to a head
float g_prob_th = 1.0f;
//threshold on the variance of the leaves
float g_maxv = 1000.f;
//stride (how densely to sample test patches - increase for higher speed)
int g_stride = 5;
//radius used for clustering votes into possible heads
float g_larger_radius_ratio = 1.f;
//radius used for mean shift
float g_smaller_radius_ratio = 6.f;
//pointer to the actual estimator
CRForestEstimator* g_Estimate;
//input 3D image
Mat g_im3D;


double g_pixel_size = 0.1042;
uint64_t g_focal_length = 120;
float f;

ofstream fout;

bool g_first_rigid = true;
bool g_show_votes = false;
bool g_draw_triangles = false;

//for interactive visualization
//gl_camera g_camera;

std::vector< cv::Vec<float,POSE_SIZE> > g_means; //outputs
std::vector< std::vector< Vote > > g_clusters; //full clusters of votes
std::vector< Vote > g_votes; //all votes returned by the forest

//math_vector_3f g_face_curr_dir, g_face_dir(0,0,-1);

// load config file
void loadConfig(const char* filename) {

	ifstream in(filename);
	string dummy;

	if(in.is_open()) {

		// Path to trees
		in >> dummy;
		in >> g_treepath;

		// Number of trees
		in >> dummy;
		in >> g_ntrees;

		in >> dummy;
		in >> g_maxv;

		in >> dummy;
		in >> g_larger_radius_ratio;

		in >> dummy;
		in >> g_smaller_radius_ratio;

		in >> dummy;
		in >> g_stride;

		in >> dummy;
		in >> g_max_z;

		in >> dummy;
		in >> g_th;


	} else {
		cerr << "File not found " << filename << endl;
		exit(-1);
	}
	in.close();

	cout << endl << "------------------------------------" << endl << endl;
	cout << "Estimation:       " << endl;
	cout << "Trees:            " << g_ntrees << " " << g_treepath << endl;
	cout << "Stride:           " << g_stride << endl;
	cout << "Max Variance:     " << g_maxv << endl;
	cout << "Max Distance:     " << g_max_z << endl;
	cout << "Head Threshold:   " << g_th << endl;

	cout << endl << "------------------------------------" << endl << endl;

}

void init_headpose() {
    // load head pose config file and trees
    loadConfig("../config.txt");
    g_Estimate = new CRForestEstimator();
    if (!g_Estimate->loadForest(g_treepath.c_str(), g_ntrees)) {

        cerr << "could not read forest!" << endl;
        exit(-1);
    }

    // get the focal length in mm (ZPS = zero plane distance = g_focal_length)
    // get the pixel size in mm ("ZPPS" = pixel size at zero plane = g_pixel_size)
    g_pixel_size *= 2.f;
    f = g_focal_length / g_pixel_size;

    g_im3D.create(DEPTH_YRES, DEPTH_XRES, CV_32FC3);
}

int get_head_pose_estimate(Mat &depth_mat) {
    int valid_pixels = 0;
    //    generate 3D image for head pose
    for (int y = 0; y < g_im3D.rows; y++) {
        Vec3f* Mi = g_im3D.ptr<Vec3f > (y);
        for (int x = 0; x < g_im3D.cols; x++) {
            float d = (ushort) depth_mat.at<ushort > (y, x);
            if (d < g_max_z && d > 0) {
                valid_pixels++;
                Mi[x][0] = (float(d * (x - 320)) / f);
                Mi[x][1] = (float(d * (y - 240)) / f);
                Mi[x][2] = d;
            } else
                Mi[x] = 0;
        }
    }
        
    g_means.clear();
    g_votes.clear();
    g_clusters.clear();

    //run estimation
    g_Estimate->estimate(g_im3D, g_means, g_clusters, g_votes, g_stride, g_maxv, g_prob_th, g_larger_radius_ratio, g_smaller_radius_ratio, false, g_th);
    
    if(g_means.size()>0)
    {
        cout << g_means[0][3] << "," << g_means[0][4] << "," << g_means[0][5] << "," << g_means[0][0] << "," << g_means[0][1] << "," << g_means[0][2] << endl;
        return 1;
    }
	else
    {
        cout<<"Unable to determine head pose"<<endl;
        return 0;
    }
}

#endif /* HEAD_POSE_HPP_ */
