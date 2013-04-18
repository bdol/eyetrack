/* 
 * File:   label_interest_points.cpp
 * Author: root
 *
 * Created on April 17, 2013, 3:54 PM
 */

#include <iostream>
#include <fstream>
#include <opencv2/highgui/highgui.hpp>
#include "config.h"
#include "hw4.h"

using namespace std;
using namespace cv;

#define LEFT 0
#define RIGHT 1
const size_t num_points = 4;
string helper_msgs[] = {"Left Eye left Corner", "Left eye right corner", "Right eye left corner", "Right eye right corner"};
int side_of_screen[] = {LEFT, LEFT, RIGHT, RIGHT};
    

/**
 * Helper function for getClick()
 */
static void onMouse(int event, int x, int y, int, void *ptr)
{
  if(CV_EVENT_LBUTTONDBLCLK == event) {
    // left double click
    *static_cast<Point*>(ptr) = Point(x, y);
  }
}


/**
 * Display an image in a window and wait for the user to
 * double click a point in the image.
 *
 * @return A point clicked by the user.
 */
Point getClick(const string &winname, const Mat &img)
{
  Point pt(-1, -1);

  namedWindow(winname, WINDOW_FLAGS);
  setMouseCallback(winname, onMouse, &pt);

  cout << "Please double click a point in the window " << winname << endl;
  while(-1 == pt.x && -1 == pt.y) {
    imshow(winname, img);
    waitKey(30);
  }
  return pt;
}

int main(int argc, char** argv) {

    if(argc<3)
    {
        cout<<"Usage: ./label_interest_points <path_to_image> <identifying_number_for_this_image>"<<endl;
        return 1;
    }
    
    Mat im = imread(argv[1], CV_LOAD_IMAGE_COLOR);
    int identifier = atoi(argv[2]);
    
    Point p[] = {Point(1,50), Point(im.cols - 575 ,50) };
    Mat A = Mat(1,num_points*2,CV_32FC1);
    
    for(int i = 0; i<num_points; i++)
    {
        rectangle(im, Point(0,0),Point(575,75),cv::Scalar(255,255,255),CV_FILLED);
        rectangle(im, Point(im.cols - 575,0),Point(im.cols,75),cv::Scalar(255,255,255),CV_FILLED);
        if(side_of_screen[i]==LEFT)
        {
            putText(im, helper_msgs[i], cvPoint(p[LEFT].x, p[LEFT].y), 
            FONT_HERSHEY_COMPLEX_SMALL, 2, cvScalar(0,0,0), 2, CV_AA);
        }
        else
        {
            putText(im, helper_msgs[i], cvPoint(p[RIGHT].x, p[RIGHT].y), 
            FONT_HERSHEY_COMPLEX_SMALL, 2, cvScalar(0,0,0), 2, CV_AA);
        }
        Point sel = getClick("Labeller Window", im);
        A.at<float>( 2*i ) = sel.x;
        A.at<float>( 2*i+1 ) = sel.y;
    }
    cout<<"Selected points = "<<A<<endl;
    // save mat file to csv...for matlab
//    ofstream MyFile;
//    MyFile.open ("User.txt", ios::out | ios::ate | ios::app) ;
    ofstream myfilename;
    myfilename.open("Selected_Points.txt", ios::out | ios::app);
    myfilename <<"P"<<identifier<<"="<<format(A, "csv")<<endl;
    myfilename.close();
    return 0;
}

