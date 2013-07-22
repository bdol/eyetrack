/* 
 * File:   calibrate_headpose.cpp
 * Author: varsha
 *
 * Created on July 18, 2013, 2:36 PM
 */

#include <cstdlib>

using namespace std;

#include <iostream>
#include <sstream>
#include <unistd.h>
#include <vector>

#include <opencv2/opencv.hpp>
#include <opencv2/highgui/highgui.hpp>
#include <opencv/cvaux.h>
#include <opencv2/imgproc/imgproc.hpp>

#include "head_pose.hpp"
#include <regex.h>

using namespace cv;
using namespace std;

#define DEPTH_XRES 640
#define DEPTH_YRES 480
#define TOT_BOARD_NUMS 9

typedef vector<double> vec1d;

static const char *reg_pattern = ".*_([0-9])_[0-9].*";

// Constants for error estimation of head pose
float expected_yaw[TOT_BOARD_NUMS] = {27.5, -24.8, -68.19, 70.35, 0, 19.58, -17.17, -33.05, 36.87};

void get_head_pose_estimate(Mat &depth_mat) {
    int valid_pixels = 0;
    
    //    generate 3D image for head pose
    for (int y = 0; y < g_im3D.rows; y++) {
        Vec3f* Mi = g_im3D.ptr<Vec3f > (y);
        for (int x = 0; x < g_im3D.cols; x++) {
            float d = (float) depth_mat.at<ushort > (y, x);
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
}

void init_headpose() {
    // load head pose config file and trees
    loadConfig("../config.txt");
    g_Estimate = new CRForestEstimator();
    if (!g_Estimate->loadForest(g_treepath.c_str(), g_ntrees)) {

        cerr << "could not read forest!" << endl;
        exit(-1);
    }

    // ZPS = zero plane distance = g_focal_length in mm - predefined
    // ZPPS = pixel size at zero plane = g_pixel_size in mm - predefined
    g_pixel_size *= 2.f;
    f = g_focal_length / g_pixel_size;

    g_im3D.create(DEPTH_YRES, DEPTH_XRES, CV_32FC3);
}

int is_file_raw(const char *filename) {
    regex_t re;
    if (regcomp(&re, ".*raw$", REG_ICASE | REG_EXTENDED) != 0)
        return -1;
    int is_other = regexec(&re, filename, 0, NULL, 0);
    regfree(&re);
    if (is_other)
        return 0;
    else
        return 1;
}

int get_board_number(const char *filename) {
    regex_t re;
    regmatch_t match[2];

    if (regcomp(&re, reg_pattern, REG_ICASE | REG_EXTENDED) != 0)
        return -1;

    int notfound = regexec(&re, filename, (size_t) 2, match, 0);
    regfree(&re);

    if (notfound == 0) {
        //        cout<<filename[match[1].rm_so]<<" to "<<filename[match[1].rm_eo]<<endl;
        return (filename[match[1].rm_so] - '0');
    }

    //    cout<<"Not found"<<endl;
    return -1;
}

void display_headpose_results(vec1d *pose, string heading)
{
    cout<<endl<<"------------------------------"<<endl;
    cout<<heading<<endl;
    vec1d numires = *(pose);
    for(int j = 0; j<numires.size(); j++)
    {
        for(int i = 0; i<TOT_BOARD_NUMS; i++)
        {
            vec1d numires = *(pose + i);
            cout<<numires[j]<<"\t";
        }
        cout<<endl;
    }
}

void get_average_headpose(vec1d* pose, vec1d* avg_headpose)
{
    for(int i = 0; i<TOT_BOARD_NUMS; i++)
    {
        vec1d numires = *(pose + i);
        double avg = 0;
        for(int j = 0; j<numires.size(); j++)
            avg += numires[j];
        avg /= numires.size();
        avg_headpose[i].push_back(avg);
    }
}

void calibrate_headpose(vec1d *pose, vec1d *offset)
{
    vec1d avg_headpose[TOT_BOARD_NUMS];
    get_average_headpose(pose, avg_headpose);
    display_headpose_results(avg_headpose, "Mean headpose for each board number");
    for(int i = 0; i<TOT_BOARD_NUMS; i++)
    {
        offset[i].push_back(*(avg_headpose[i].begin()) - expected_yaw[i]);
    }
    display_headpose_results(offset, "Calculated Offset");
}

void get_corrected_headpose(vec1d *avg_headpose, vec1d *offset, vec1d *corrected_headpose)
{
    for(int i = 0; i<TOT_BOARD_NUMS; i++)
    {
        corrected_headpose[i].push_back(*(avg_headpose[i].begin()) - *(offset[i].begin()));
    }
    display_headpose_results(corrected_headpose, "Corrected headpose and Expected Values");
    for(int i = 0; i<TOT_BOARD_NUMS; i++)
    {
        cout<<expected_yaw[i]<<"\t";
    }
    cout<<endl;
}

void process_depth_file_headpose(string input_file_path, vec1d* headpose)
{
    ifstream fin(input_file_path.c_str());
    // check for bogus paths
    if (!fin.is_open()) {
        cout << "Could not open input file : " << input_file_path << endl;
        return;
    }
    
    string depth_file_name;
    int current_board_number, is_raw, file_open;
    Mat depth_mat;
    
    while (fin.good()) {
        getline(fin, depth_file_name);
        current_board_number = get_board_number(depth_file_name.c_str());
        is_raw = is_file_raw(depth_file_name.c_str());
        char *data;
        if (is_raw) {
            // create a depth cv::mat
            ifstream fin(depth_file_name.c_str(), ios::binary | ios::ate);
            ifstream::pos_type size = fin.tellg();
            fin.seekg(0, ios::beg);
            data = new char[size];
            fin.read(data, size);
            fin.close();
            depth_mat = Mat(DEPTH_YRES, DEPTH_XRES, CV_16UC1, (void*) data);
            file_open = 1;
            delete[] data;
        } else {
            depth_mat = imread(depth_file_name.c_str(), CV_16UC1);
            file_open = 1;
        }
        
        if (file_open && (current_board_number != -1)) {
            // run head pose estimation
            get_head_pose_estimate(depth_mat);
            // write to file if valid pose is returned
            if (g_means.size() > 0) {
                headpose[current_board_number-1].push_back(g_means[0][4]);
                
//                cout << "SUCCESS Processed : " << depth_file_name << endl;
            } else {
//                cout << "FAILED Processed : " << depth_file_name << endl;
            }
        } else
            cout << "Failed to open :" << depth_file_name << endl;
    }
}

int main(int argc, const char * argv[]) {

    string input_file_path = "/fiddlestix/Users/varsha/Documents/ResearchEyetrackCode/eyetrack/MyNiViewer/Default/calibrate_headpose_2/calibrate/depth_file_list.txt";
    string test_file_path = "/fiddlestix/Users/varsha/Documents/ResearchEyetrackCode/eyetrack/MyNiViewer/Default/calibrate_headpose_2/test_2/test_file_list.txt";

    // initialise head pose setup
    init_headpose();
    
    vec1d headpose[TOT_BOARD_NUMS];
    process_depth_file_headpose(input_file_path, headpose);    
    display_headpose_results(headpose, "Raw Estimated headpose");
    vec1d offset[TOT_BOARD_NUMS];
    calibrate_headpose(headpose, offset);
    
    vec1d test_headpose[TOT_BOARD_NUMS];
    process_depth_file_headpose(test_file_path, test_headpose);
    
    vec1d avg_headpose[TOT_BOARD_NUMS], corrected_headpose[TOT_BOARD_NUMS];
    get_average_headpose(test_headpose, avg_headpose);
    get_corrected_headpose(avg_headpose, offset, corrected_headpose);
    
    return 0;
}

