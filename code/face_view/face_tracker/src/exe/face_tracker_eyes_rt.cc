///////////////////////////////////////////////////////////////////////////////
// Copyright (C) 2010, Jason Mora Saragih, all rights reserved.
//
// This file is part of FaceTracker.
//
// Redistribution and use in source and binary forms, with or without 
// modification, are permitted provided that the following conditions are met:
//
//     * The software is provided under the terms of this licence stricly for
//       academic, non-commercial, not-for-profit purposes.
//     * Redistributions of source code must retain the above copyright notice, 
//       this list of conditions (licence) and the following disclaimer.
//     * Redistributions in binary form must reproduce the above copyright 
//       notice, this list of conditions (licence) and the following disclaimer 
//       in the documentation and/or other materials provided with the 
//       distribution.
//     * The name of the author may not be used to endorse or promote products 
//       derived from this software without specific prior written permission.
//     * As this software depends on other libraries, the user must adhere to 
//       and keep in place any licencing terms of those libraries.
//     * Any publications arising from the use of this software, including but
//       not limited to academic journal and conference publications, technical
//       reports and manuals, must cite the following work:
//
//       J. M. Saragih, S. Lucey, and J. F. Cohn. Face Alignment through 
//       Subspace Constrained Mean-Shifts. International Conference of Computer 
//       Vision (ICCV), September, 2009.
//
// THIS SOFTWARE IS PROVIDED BY THE AUTHOR "AS IS" AND ANY EXPRESS OR IMPLIED 
// WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF 
// MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO 
// EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, 
// INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES 
// (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
// LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
// ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT 
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF 
// THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
///////////////////////////////////////////////////////////////////////////////
#include <FaceTracker/Tracker.h>
#include <opencv/highgui.h>
#include <iostream>
#include <fstream>
#include <string>

using namespace cv;
using namespace std;
//=============================================================================
void Draw(cv::Mat &image,cv::Mat &shape,cv::Mat &con,cv::Mat &tri,cv::Mat &visi)
{
  int i,n = shape.rows/2; cv::Point p1,p2; cv::Scalar c;

  //c = CV_RGB(0,0,0);
  //for(i = 0; i < tri.rows; i++){
    //if(visi.at<int>(tri.at<int>(i,0),0) == 0 ||
       //visi.at<int>(tri.at<int>(i,1),0) == 0 ||
       //visi.at<int>(tri.at<int>(i,2),0) == 0)continue;
    //p1 = cv::Point(shape.at<double>(tri.at<int>(i,0),0),
		   //shape.at<double>(tri.at<int>(i,0)+n,0));
    //p2 = cv::Point(shape.at<double>(tri.at<int>(i,1),0),
		   //shape.at<double>(tri.at<int>(i,1)+n,0));
    //cv::line(image,p1,p2,c);
    //p1 = cv::Point(shape.at<double>(tri.at<int>(i,0),0),
		   //shape.at<double>(tri.at<int>(i,0)+n,0));
    //p2 = cv::Point(shape.at<double>(tri.at<int>(i,2),0),
		   //shape.at<double>(tri.at<int>(i,2)+n,0));
    //cv::line(image,p1,p2,c);
    //p1 = cv::Point(shape.at<double>(tri.at<int>(i,2),0),
		   //shape.at<double>(tri.at<int>(i,2)+n,0));
    //p2 = cv::Point(shape.at<double>(tri.at<int>(i,1),0),
		   //shape.at<double>(tri.at<int>(i,1)+n,0));
    //cv::line(image,p1,p2,c);
  //}
  //draw connections
  //for(i = 0; i < con.cols; i++){
      //if (i>=31 && i<=42) {
          //c = CV_RGB(255,255,255);
        //if(visi.at<int>(con.at<int>(0,i),0) == 0 ||
           //visi.at<int>(con.at<int>(1,i),0) == 0)continue;
        //p1 = cv::Point(shape.at<double>(con.at<int>(0,i),0),
               //shape.at<double>(con.at<int>(0,i)+n,0));
        //p2 = cv::Point(shape.at<double>(con.at<int>(1,i),0),
               //shape.at<double>(con.at<int>(1,i)+n,0));
        //cv::line(image,p1,p2,c,1);
        //c = CV_RGB(255,0,0); cv::circle(image,p2,2,c);
      //}
  //}
  //draw points
  //for(i = 0; i < n; i++){    
    //if(visi.at<int>(i,0) == 0)continue;
    //p1 = cv::Point(shape.at<double>(i,0),shape.at<double>(i+n,0));
    //c = CV_RGB(255,0,0); cv::circle(image,p1,2,c);
  //}
  return;
}

void writeEyesToFile(Mat left, Mat right, string filename)
{
    ofstream f;
    f.open(filename.c_str());

    flip(left, left, 1);
    flip(right, right, 1);

    // Write label (which is unknown in this case, so just set it to 0)
    f << "0 ";
    

    // Write left eye in column major order
    int featCount = 1;
    for (int x=0; x<left.cols; x++) {
        for (int y=0; y<left.rows; y++) {
            f << featCount << ":" << left.at<float>(y, x) << " ";
            featCount++;
        }
    }
    // Write right eye in column major order
    for (int x=0; x<right.cols; x++) {
        for (int y=0; y<right.rows; y++) {
            f << featCount << ":" << right.at<float>(y, x) << " ";
            featCount++;
        }
    }

    f << endl;

    f.close();
}

void runSVM(string filename, string output_filename)
{
    stringstream cmd;
    cmd << "./svm-predict -q -b 1 " << filename << " train.model " << output_filename;
    system(cmd.str().c_str());
}

void debugSVM(string leftName, string rightName)
{
    Mat left = imread(leftName, CV_LOAD_IMAGE_COLOR);
    cvtColor(left, left, CV_RGB2GRAY);
    normalize(left, left, 0, 1, NORM_MINMAX, CV_32F);
    flip(left, left, 1);

    Mat right = imread(rightName, CV_LOAD_IMAGE_COLOR);
    cvtColor(right, right, CV_RGB2GRAY);
    normalize(right, right, 0, 1, NORM_MINMAX, CV_32F);
    flip(right, right, 1);
    writeEyesToFile(left, right, "test_eye.data");
    runSVM("test_eye.data", "debug.output");

}

void updatePredictions(Mat &im, string output_filename)
{
    string line;
    ifstream preds(output_filename.c_str());
    if (preds.is_open()) {
        getline(preds, line); // Skip the first line which has label info
        getline(preds, line); 

        istringstream iss(line);
        string token;
        bool isLabel = true;
        int predNum = 1;
        while (std::getline(iss, token, ' '))  {
            if (isLabel) { // Skip the first token, which is the predicted label
                isLabel = false;
            } else {
                stringstream predVal;
                switch(predNum) {
                    float p;
                    case 1:
                        predVal << "L: " << token;
                        putText(im, predVal.str(), Point(30, 30), CV_FONT_HERSHEY_PLAIN, 1, Scalar(255, 255, 255));
                        p = atof(token.c_str());
                        rectangle(im, Point(30, 40), Point(p*300.0+30, 50), Scalar(255, 0, 0), CV_FILLED);
                        break;
                    case 2:
                        predVal << "R: " << token;
                        p = atof(token.c_str());
                        rectangle(im, Point(30, 120), Point(p*300.0+30, 130), Scalar(0, 255, 0), CV_FILLED);
                        putText(im, predVal.str(), Point(30, 110), CV_FONT_HERSHEY_PLAIN, 1, Scalar(255, 255, 255));
                    break;
                    case 3:
                        predVal << "C: " << token;
                        p = atof(token.c_str());
                        rectangle(im, Point(30, 80), Point(p*300.0+30, 90), Scalar(0, 0, 255), CV_FILLED);
                        putText(im, predVal.str(), Point(30, 70), CV_FONT_HERSHEY_PLAIN, 1, Scalar(255, 255, 255));
                    break;
                }
                predNum++;

            }
        }

    }

}

//=============================================================================
void ExtractAndShowEyes(cv::Mat &image, cv::Mat &shape, cv::Mat &con, cv::Mat &visi)
{
    int n = shape.rows/2;
    double n_points_per_eye = 6.0;
    cv::Point l_centroid, r_centroid, pr, pl;
    cv::Scalar c;
    double bb_width = 100;
    double bb_height = 50;

    // Left eye con indices: [31 37]
    // Right eye con indices: [37 42]
    // Compute left eye centroid
    double lx, ly = 0.0;
    for (int i=31; i<=36; i++) {
        lx += (double)(shape.at<double>(con.at<int>(0,i),0));
        ly += (double)(shape.at<double>(con.at<int>(0,i)+n,0));
    }
    lx /= n_points_per_eye;
    ly /= n_points_per_eye;
    c = CV_RGB(0, 255, 0);
    l_centroid = cv::Point(lx, ly);
    pl = cv::Point(shape.at<double>(con.at<int>(0,31),0),
               shape.at<double>(con.at<int>(0,31)+n,0));
    // Compute right eye centroid
    double rx, ry = 0.0;
    for (int i=37; i<=42; i++) {
        rx += (double)(shape.at<double>(con.at<int>(0,i),0));
        ry += (double)(shape.at<double>(con.at<int>(0,i)+n,0));
    }
    rx /= n_points_per_eye;
    ry /= n_points_per_eye;
    c = CV_RGB(0, 255, 0);
    r_centroid = cv::Point(rx, ry);
    pr = cv::Point(shape.at<double>(con.at<int>(0,37),0),
               shape.at<double>(con.at<int>(0,37)+n,0));

    cout << rx << " " << ry << " " << lx << " " << ly << endl;
    if (rx < 0 || ry < 0 || lx < 0 || ly < 0) {
        return;
    }


    // Compute bounding boxes
    cv::Point lb1 = cv::Point(l_centroid.x - bb_width/2.0, l_centroid.y - bb_height/2.0);
    cv::Point lb2 = cv::Point(l_centroid.x + bb_width/2.0, l_centroid.y + bb_height/2.0);
    cv::Point rb1 = cv::Point(r_centroid.x - bb_width/2.0, r_centroid.y - bb_height/2.0);
    cv::Point rb2 = cv::Point(r_centroid.x + bb_width/2.0, r_centroid.y + bb_height/2.0);

    cv::Rect left_eye_rect = cv::Rect(l_centroid.x-bb_width/2.0, l_centroid.y-bb_height/2.0, bb_width, bb_height);
    cv::Mat left_eye = image(left_eye_rect).clone();
    cv::Rect right_eye_rect = cv::Rect(r_centroid.x-bb_width/2.0, r_centroid.y-bb_height/2.0, bb_width, bb_height);
    cv::Mat right_eye = image(right_eye_rect).clone();

    // Write gray eyes to file for SVM
    Mat left_eye_gray, right_eye_gray;
    cvtColor(left_eye, left_eye_gray, CV_RGB2GRAY);
    normalize(left_eye_gray, left_eye_gray, 0, 1, NORM_MINMAX, CV_32F);

    cvtColor(right_eye, right_eye_gray, CV_RGB2GRAY);
    normalize(right_eye_gray, right_eye_gray, 0, 1, NORM_MINMAX, CV_32F);
    writeEyesToFile(left_eye_gray, right_eye_gray, "eyes.data");
    runSVM("eyes.data", "test.output");
    
    // Rescale eyes to be bigger
    int scale = 4;
    cv::Mat left_eye_big, right_eye_big;
    cv::resize(left_eye, left_eye_big, cv::Size(scale*left_eye.cols,scale*left_eye.rows));
    cv::resize(right_eye, right_eye_big, cv::Size(scale*right_eye.cols,scale*right_eye.rows));

    // Convert to grayscale and normalize for display purposes
    Mat left_eye_big_gray, right_eye_big_gray;
    cvtColor(left_eye_big, left_eye_big_gray, CV_RGB2GRAY);
    normalize(left_eye_big_gray, left_eye_big_gray, 0, 1, NORM_MINMAX, CV_32F);
    flip(left_eye_big_gray, left_eye_big_gray, 1);

    cvtColor(right_eye_big, right_eye_big_gray, CV_RGB2GRAY);
    normalize(right_eye_big_gray, right_eye_big_gray, 0, 1, NORM_MINMAX, CV_32F);
    flip(right_eye_big_gray, right_eye_big_gray, 1);

    imshow("Left Eye", left_eye_big_gray);
    imshow("Right Eye", right_eye_big_gray);
    //imshow("Left Eye", left_eye_gray);
    //imshow("Right Eye", right_eye_gray);
    
    updatePredictions(image, "test.output");

    // Debug 
    cv::rectangle(image, lb1, lb2, c);
    cv::rectangle(image, rb1, rb2, c);
    cv::line(image,l_centroid,pl,c,1);
    cv::line(image,r_centroid,pr,c,1);

    //debugSVM("/Users/bdol/code/eyetrack_data/cropped_eyes_clean/1001.2.E/1/IM_1_1_left.png", "/Users/bdol/code/eyetrack_data/cropped_eyes_clean/1001.2.E/1/IM_1_1_right.png");

    return;
}
//=============================================================================
int parse_cmd(int argc, const char** argv,
	      char* ftFile,char* conFile,char* triFile,
	      bool &fcheck,double &scale,int &fpd)
{
  int i; fcheck = false; scale = 1; fpd = -1;
  for(i = 1; i < argc; i++){
    if((std::strcmp(argv[i],"-?") == 0) ||
       (std::strcmp(argv[i],"--help") == 0)){
      std::cout << "track_face:- Written by Jason Saragih 2010" << std::endl
	   << "Performs automatic face tracking" << std::endl << std::endl
	   << "#" << std::endl 
	   << "# usage: ./face_tracker [options]" << std::endl
	   << "#" << std::endl << std::endl
	   << "Arguments:" << std::endl
	   << "-m <string> -> Tracker model (default: ../model/face2.tracker)"
	   << std::endl
	   << "-c <string> -> Connectivity (default: ../model/face.con)"
	   << std::endl
	   << "-t <string> -> Triangulation (default: ../model/face.tri)"
	   << std::endl
	   << "-s <double> -> Image scaling (default: 1)" << std::endl
	   << "-d <int>    -> Frames/detections (default: -1)" << std::endl
	   << "--check     -> Check for failure" << std::endl;
      return -1;
    }
  }
  for(i = 1; i < argc; i++){
    if(std::strcmp(argv[i],"--check") == 0){fcheck = true; break;}
  }
  if(i >= argc)fcheck = false;
  for(i = 1; i < argc; i++){
    if(std::strcmp(argv[i],"-s") == 0){
      if(argc > i+1)scale = std::atof(argv[i+1]); else scale = 1;
      break;
    }
  }
  if(i >= argc)scale = 1;
  for(i = 1; i < argc; i++){
    if(std::strcmp(argv[i],"-d") == 0){
      if(argc > i+1)fpd = std::atoi(argv[i+1]); else fpd = -1;
      break;
    }
  }
  if(i >= argc)fpd = -1;
  for(i = 1; i < argc; i++){
    if(std::strcmp(argv[i],"-m") == 0){
      if(argc > i+1)std::strcpy(ftFile,argv[i+1]);
      else strcpy(ftFile,"../model/face2.tracker");
      break;
    }
  }
  if(i >= argc)std::strcpy(ftFile,"../model/face2.tracker");
  for(i = 1; i < argc; i++){
    if(std::strcmp(argv[i],"-c") == 0){
      if(argc > i+1)std::strcpy(conFile,argv[i+1]);
      else strcpy(conFile,"../model/face.con");
      break;
    }
  }
  if(i >= argc)std::strcpy(conFile,"../model/face.con");
  for(i = 1; i < argc; i++){
    if(std::strcmp(argv[i],"-t") == 0){
      if(argc > i+1)std::strcpy(triFile,argv[i+1]);
      else strcpy(triFile,"../model/face.tri");
      break;
    }
  }
  if(i >= argc)std::strcpy(triFile,"../model/face.tri");
  return 0;
}
//=============================================================================
int main(int argc, const char** argv)
{
  //parse command line arguments
  char ftFile[256],conFile[256],triFile[256];
  bool fcheck = false; double scale = 1; int fpd = -1; bool show = false;
  if(parse_cmd(argc,argv,ftFile,conFile,triFile,fcheck,scale,fpd)<0)return 0;

  //set other tracking parameters
  std::vector<int> wSize1(1); wSize1[0] = 7;
  std::vector<int> wSize2(3); wSize2[0] = 11; wSize2[1] = 9; wSize2[2] = 7;
  int nIter = 5; double clamp=3,fTol=0.01; 
  FACETRACKER::Tracker model(ftFile);
  cv::Mat tri=FACETRACKER::IO::LoadTri(triFile);
  cv::Mat con=FACETRACKER::IO::LoadCon(conFile);
  
  //initialize camera and display window
  cv::Mat frame,gray,im; double fps=0; char sss[256]; std::string text; 
  CvCapture* camera = cvCreateCameraCapture(CV_CAP_ANY); if(!camera)return -1;
  int64 t1,t0 = cvGetTickCount(); int fnum=0;
  cvNamedWindow("Face Tracker",1);
  std::cout << "Hot keys: "        << std::endl
	    << "\t ESC - quit"     << std::endl
	    << "\t d   - Redetect" << std::endl;

  //loop until quit (i.e user presses ESC)
  bool failed = true;
  while(1){ 
    //grab image, resize and flip
    IplImage* I = cvQueryFrame(camera); if(!I)continue; frame = I;
    if(scale == 1)im = frame; 
    else cv::resize(frame,im,cv::Size(scale*frame.cols,scale*frame.rows));
    cv::flip(im,im,1); cv::cvtColor(im,gray,CV_BGR2GRAY);

    //track this image
    std::vector<int> wSize; if(failed)wSize = wSize2; else wSize = wSize1; 
    if(model.Track(gray,wSize,fpd,nIter,clamp,fTol,fcheck) == 0){
      int idx = model._clm.GetViewIdx(); failed = false;
        ExtractAndShowEyes(im, model._shape, con, model._clm._visi[idx]);
    }else{
      if(show){cv::Mat R(im,cvRect(0,0,150,50)); R = cv::Scalar(0,0,255);}
      model.FrameReset(); failed = true;
    }
    
    //draw framerate on display image 
    if(fnum >= 9){      
      t1 = cvGetTickCount();
      fps = 10.0/((double(t1-t0)/cvGetTickFrequency())/1e+6); 
      t0 = t1; fnum = 0;
    }else fnum += 1;
    if(show){
      sprintf(sss,"%d frames/sec",(int)round(fps)); text = sss;
      cv::putText(im,text,cv::Point(10,20),
		  CV_FONT_HERSHEY_SIMPLEX,0.5,CV_RGB(255,255,255));
    }

    // Extract eyes

    //show image and check for user input
    imshow("Face Tracker",im); 

    int c = cvWaitKey(10);
    if(c == 27)break; else if(char(c) == 'd')model.FrameReset();
  }return 0;
}
//=============================================================================
