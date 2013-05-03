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

//=============================================================================
void ExtractAndSaveEyes(cv::Mat &image, cv::Mat &shape, cv::Mat &con, cv::Mat &visi, char* outDir, int i)
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

    // Compute bounding boxes
    cv::Point lb1 = cv::Point(l_centroid.x - bb_width/2.0, l_centroid.y - bb_height/2.0);
    cv::Point lb2 = cv::Point(l_centroid.x + bb_width/2.0, l_centroid.y + bb_height/2.0);
    cv::Point rb1 = cv::Point(r_centroid.x - bb_width/2.0, r_centroid.y - bb_height/2.0);
    cv::Point rb2 = cv::Point(r_centroid.x + bb_width/2.0, r_centroid.y + bb_height/2.0);

    cv::Rect left_eye_rect = cv::Rect(l_centroid.x-bb_width/2.0, l_centroid.y-bb_height/2.0, bb_width, bb_height);
    cv::Mat left_eye = image(left_eye_rect).clone();
    cv::Rect right_eye_rect = cv::Rect(r_centroid.x-bb_width/2.0, r_centroid.y-bb_height/2.0, bb_width, bb_height);
    cv::Mat right_eye = image(right_eye_rect).clone();

    // Rescale eyes to be bigger
    int scale = 4;
    cv::Mat left_eye_big, right_eye_big;
    cv::resize(left_eye, left_eye_big, cv::Size(scale*left_eye.cols,scale*left_eye.rows));
    cv::resize(right_eye, right_eye_big, cv::Size(scale*right_eye.cols,scale*right_eye.rows));
    
    std::stringstream s;
    s << outDir << i << "left" << ".png";
    imwrite(s.str(), left_eye_big);
    s.str("");
    s << outDir << i << "right" << ".png";
    imwrite(s.str(), right_eye_big);

}

//=============================================================================
int parse_cmd(int argc, const char** argv,
        char* ftFile,char* conFile,char* triFile,
        bool &fcheck,double &scale,int &fpd,
        char* inFile, char* outDir)
{
    if (argc < 3) {
        std::cout << "Usage: ./face_tracker_single_frame <infile> <outfile>" << std::endl;
        return -1;
    }
    int i; fcheck = false; scale = 1; fpd = -1;
    std::strcpy(ftFile,"../model/face2.tracker");
    std::strcpy(conFile,"../model/face.con");
    std::strcpy(triFile,"../model/face.tri");
    std::strcpy(inFile, argv[1]);
    std::strcpy(outDir, argv[2]);

    return 0;

    return 0;
}
//=============================================================================
int main(int argc, const char** argv)
{
    //parse command line arguments
    char ftFile[256],conFile[256],triFile[256];
    bool fcheck = false; double scale = 1; int fpd = -1; bool show = true;
    char inFile[1024]; char outDir[1024];
    if(parse_cmd(argc,argv,ftFile,conFile,triFile,fcheck,scale,fpd,inFile,outDir)<0)return 0;

    //set other tracking parameters
    std::vector<int> wSize1(1); wSize1[0] = 7;
    std::vector<int> wSize2(3); wSize2[0] = 11; wSize2[1] = 9; wSize2[2] = 7;
    int nIter = 5; double clamp=3,fTol=0.01; 
    FACETRACKER::Tracker model(ftFile);
    cv::Mat tri=FACETRACKER::IO::LoadTri(triFile);
    cv::Mat con=FACETRACKER::IO::LoadCon(conFile);

    //initialize camera and display window
    cv::Mat frame,gray,im; double fps=0; char sss[256]; std::string text; 
    int64 t1,t0 = cvGetTickCount(); int fnum=0;
    bool failed = true;

    std::ifstream frameFile(inFile);
    std::string line;
    int i=0;
    while(std::getline(frameFile, line)){ 
        //grab image, resize and flip
        std::cout << line << std::endl; 
        cv::Mat image = cv::imread(line, 1);
        IplImage* I = cvCloneImage(&(IplImage)image);
        frame = I;
        if(scale == 1)im = frame; 
        else cv::resize(frame,im,cv::Size(scale*frame.cols,scale*frame.rows));
        cv::flip(im,im,1); cv::cvtColor(im,gray,CV_BGR2GRAY);

        //track this image
        std::vector<int> wSize; if(failed)wSize = wSize2; else wSize = wSize1; 
        if(model.Track(gray,wSize,fpd,nIter,clamp,fTol,fcheck) == 0){
            int idx = model._clm.GetViewIdx(); failed = false;
            ExtractAndSaveEyes(im, model._shape, con, model._clm._visi[idx], outDir, i);
            //Draw(im,model._shape,con,tri,model._clm._visi[idx]); 
        }else{
            if(show){cv::Mat R(im,cvRect(0,0,150,50)); R = cv::Scalar(0,0,255);}
            model.FrameReset(); failed = true;
        }

        i++;

        int c = cvWaitKey(10);
        if(c == 27)break; else if(char(c) == 'd')model.FrameReset();
    }return 0;
}
//=============================================================================
