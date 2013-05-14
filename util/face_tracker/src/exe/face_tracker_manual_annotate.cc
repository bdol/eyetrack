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
#include <opencv2/highgui/highgui_c.h>
//=============================================================================
#define CON_LEFT_BEGIN 31
#define CON_RIGHT_BEGIN 37
#define CON_LEFT_END 36
#define CON_RIGHT_END 42
#define SHAPE_LEFT_BEGIN 36
#define SHAPE_RIGHT_BEGIN 42
#define SHAPE_LEFT_END 41
#define SHAPE_RIGHT_END 47
#define DISPLAY_WINDOW_NAME "Face Tracker"
#define SIZE_EYE_POINTS_ARRAY (SHAPE_RIGHT_END-SHAPE_LEFT_BEGIN+1)

/**
 * Helper function for getClick()
 */
static void onMouse(int event, int x, int y, int, void *ptr)
{
  if(CV_EVENT_LBUTTONDBLCLK == event) {
      // left double click
    *static_cast<cv::Point*>(ptr) = cv::Point(x, y);
  }
  else if(CV_EVENT_RBUTTONDBLCLK == event) {
      // right double click - no change required to point in case of right double click
    *static_cast<cv::Point*>(ptr) = cv::Point(-2,-2);
  }
}

/**
 * Display an image in a window and wait for the user to
 * left double click a point in the image.
 *
 * @return A point clicked by the user.
 */
cv::Point getClick(const cv::Mat &img)
{
  cv::Point pt(-1, -1);

  cv::setMouseCallback(DISPLAY_WINDOW_NAME, onMouse, &pt);

  while(-1 == pt.x && -1 == pt.y) {
        cv::imshow(DISPLAY_WINDOW_NAME, img);
        cv::waitKey(30);
  }
  return pt;
}

/**
 * yellow circle around a point indicates a currently editable point
 * LEFT DOUBLE CLICK TO CHANGE THE POINT
 * RIGHT DOUBLE CLICK TO LEAVE UNCHANGED
 * @param image
 * @param shape
 * @param visi
 * @param new_points
 */
void EditPointsAroundEye(cv::Mat &image,cv::Mat &shape,cv::Mat &visi,cv::Point *&new_points)
{
    cv::Scalar colour_selected = CV_RGB(255,255,0);
    cv::Scalar colour = CV_RGB(255,0,0);
    int n = shape.rows/2;
    int count = 0;
    new_points = new cv::Point[SIZE_EYE_POINTS_ARRAY];
    //RIGHT EYE
    for(int i = SHAPE_RIGHT_BEGIN; i <= SHAPE_RIGHT_END; i++,count++)
    {    
        if(visi.at<int>(i,0) == 0)continue;
        cv::Point p1 = cv::Point(shape.at<double>(i,0),shape.at<double>(i+n,0));
        cv::circle(image,p1,2,colour_selected);
        cv::Point new_p1 = getClick(image);
//        std::cout<<"You clicked: "<<new_p1<<std::endl;
        cv::circle(image,p1,2,colour);
        if(new_p1.x==-2)
            new_points[count] = p1;
        else
            new_points[count] = new_p1;
    }
    //LEFT EYE
    for(int i = SHAPE_LEFT_BEGIN; i <= SHAPE_LEFT_END; i++,count++)
    {    
        if(visi.at<int>(i,0) == 0)continue;
        cv::Point p1 = cv::Point(shape.at<double>(i,0),shape.at<double>(i+n,0));
        cv::circle(image,p1,2,colour_selected);
        cv::Point new_p1 = getClick(image);
        cv::circle(image,p1,2,colour);
        if(new_p1.x==-2)
            new_points[count] = p1;
        else
            new_points[count] = new_p1;
    }
}

/**
 * helper function to print stored new and original points
 * @param new_points
 * @param shape
 * @param original_pts
 */
void print_points(cv::Point* new_points, cv::Mat &shape, bool original_pts=0)
{
    
    if(original_pts)
    {
        std::cout<<"\nOriginal Points\n[";
       int n = shape.rows/2; 
       for(int i = SHAPE_LEFT_BEGIN; i <= SHAPE_RIGHT_END; i++)
        {
           cv::Point p1 = cv::Point(shape.at<double>(i,0),shape.at<double>(i+n,0));
           std::cout<<"("<<p1.x<<","<<p1.y<<")"<<std::endl;
        }
    }
    else
    {
        std::cout<<"\nNew Points\n[";
        for(int i = 0; i < SIZE_EYE_POINTS_ARRAY; i++)
        {
            std::cout<<"("<<new_points[i].x<<","<<new_points[i].y<<")"<<std::endl;
        }
    }
    std::cout<<"]";
}

/**
 * helper function to draw new and original points on image after editing
 * @param image
 * @param shape
 * @param visi
 * @param new_points
 */
void DrawAnnotatedPoints(cv::Mat &image,cv::Mat &shape,cv::Mat &visi,cv::Point* new_points)
{
   int i,n = shape.rows/2; cv::Point p1,p2; 
   cv::Scalar colour = CV_RGB(255,255,0);
  //draw points only around the eye
  for(i = SHAPE_LEFT_BEGIN; i <= SHAPE_RIGHT_END; i++)
  {    
    if(visi.at<int>(i,0) == 0)continue;
    p1 = new_points[i-SHAPE_LEFT_BEGIN];
    cv::circle(image,p1,2,colour);
  }
}

void Draw(cv::Mat &image,cv::Mat &shape,cv::Mat &con,cv::Mat &visi)
{
  int i,n = shape.rows/2; cv::Point p1,p2; cv::Scalar c;

  //draw connections
  c = CV_RGB(0,0,255);
    for(i = CON_LEFT_BEGIN; i <= CON_RIGHT_END; i++){
    if(visi.at<int>(con.at<int>(0,i),0) == 0 ||
       visi.at<int>(con.at<int>(1,i),0) == 0)continue;
    p1 = cv::Point(shape.at<double>(con.at<int>(0,i),0),
		   shape.at<double>(con.at<int>(0,i)+n,0));
    p2 = cv::Point(shape.at<double>(con.at<int>(1,i),0),
		   shape.at<double>(con.at<int>(1,i)+n,0));
    cv::line(image,p1,p2,c,1);
  }
  //draw points only around the eye
  for(i = SHAPE_LEFT_BEGIN; i <= SHAPE_RIGHT_END; i++){    
    if(visi.at<int>(i,0) == 0)continue;
    p1 = cv::Point(shape.at<double>(i,0),shape.at<double>(i+n,0));
    c = CV_RGB(255,0,0); cv::circle(image,p1,2,c);
  }return;
}
//=============================================================================
int parse_cmd(int argc, const char** argv,
	      char* ftFile,char* conFile,char* triFile,
	      bool &fcheck,double &scale,int &fpd, char*inputFile, char*outputFile, char*inputListFile)
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
	   << "--check     -> Check for failure" << std::endl
       << "-i <string> -> filename of image to be loaded" << std::endl
       << "-f <string> -> output filename for new eye points" << std::endl
       << "-ilist <string> -> filename of image list to be loaded" << std::endl;
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
  for(i = 1; i < argc; i++){
    if(std::strcmp(argv[i],"-i") == 0){
      if(argc > i+1)std::strcpy(inputFile,argv[i+1]);
      else strcpy(inputFile,"");
      break;
    }
  }
  for(i = 1; i < argc; i++){
    if(std::strcmp(argv[i],"-f") == 0){
      if(argc > i+1)std::strcpy(outputFile,argv[i+1]);
      else strcpy(outputFile,"");
      break;
    }
  }
  if(i >= argc)std::strcpy(outputFile,"new_eye_points.txt");
  for(i = 1; i < argc; i++){
    if(std::strcmp(argv[i],"-ilist") == 0){
      if(argc > i+1)std::strcpy(inputListFile,argv[i+1]);
      else strcpy(inputListFile,"");
      break;
    }
  }
  return 0;
}
//=============================================================================
int main(int argc, const char** argv)
{
  //parse command line arguments
  char ftFile[256],conFile[256],triFile[256],inputFile[256],outputFile[256], inputListFile[256];
  bool fcheck = false; double scale = 1; int fpd = -1; bool show = true;
  if(parse_cmd(argc,argv,ftFile,conFile,triFile,fcheck,scale,fpd,inputFile,outputFile, inputListFile)<0)return 0;

  //set other tracking parameters
  std::vector<int> wSize1(1); wSize1[0] = 7;
  std::vector<int> wSize2(3); wSize2[0] = 11; wSize2[1] = 9; wSize2[2] = 7;
  int nIter = 5; double clamp=3,fTol=0.01; 
  FACETRACKER::Tracker model(ftFile);
  cv::Mat tri=FACETRACKER::IO::LoadTri(triFile);
  cv::Mat con=FACETRACKER::IO::LoadCon(conFile);
  
  //initialize camera and display window
  cv::Mat frame,gray,im,im_res; double fps=0; char sss[256]; std::string text; 
  CvCapture* camera;
  if(std::strcmp(inputFile,"")==0)
  {
    camera = cvCreateCameraCapture(CV_CAP_ANY); if(!camera)return -1;
  }
  int64 t1,t0 = cvGetTickCount(); int fnum=0;
  cvNamedWindow(DISPLAY_WINDOW_NAME,1);
  std::cout << "Hot keys: "        << std::endl
	    << "\t ESC - quit"     << std::endl
	    << "\t d   - Redetect" << std::endl;

  if(std::strcmp(inputListFile,"")!=0)
  {
      std::cout<<"Processing an image list file\n";
      std::ifstream inputlist_stream;
      inputlist_stream.open(inputListFile,std::ios::in);
      if(inputlist_stream.is_open())
      {
          std::string inputFile;
          while(inputlist_stream.good())
          {
              getline(inputlist_stream,inputFile);
//              std::cout<<inputFile<<std::endl;
              bool failed = true;
                //grab image, resize and flip
                frame = cv::imread(inputFile, CV_LOAD_IMAGE_COLOR);
                if(scale == 1)
                {
                    im = frame; im_res = frame;
                }
                else 
                    cv::resize(frame,im,cv::Size(scale*frame.cols,scale*frame.rows));

                cv::flip(im,im,1); 
                cv::cvtColor(im,gray,CV_BGR2GRAY);
                im_res = im;
                //track this image
                std::vector<int> wSize; if(failed)wSize = wSize2; else wSize = wSize1; 
                cv::Point* new_points;
                if(model.Track(gray,wSize,fpd,nIter,clamp,fTol,fcheck) == 0){
                int idx = model._clm.GetViewIdx(); failed = false;
                Draw(im,model._shape,con,model._clm._visi[idx]); 
                EditPointsAroundEye(im,model._shape,model._clm._visi[idx],new_points);
                }else{
                if(show){cv::Mat R(im,cvRect(0,0,150,50)); R = cv::Scalar(0,0,255);}
                model.FrameReset(); failed = true;
                }     
                if(new_points)
                {
                    // print results to file
                    std::ofstream filestream;
                    filestream.open(outputFile, std::ios::app);
                    if(filestream.is_open())
                    {
                        filestream<<inputFile<<" ";
                        for(int i = 0; i < SIZE_EYE_POINTS_ARRAY; i++)
                        {
                            filestream<<new_points[i].x<<" "<<new_points[i].y<<" ";
                        }
                        filestream<<std::endl;
                        filestream.close();
                    }
                    else
                        std::cout<<"Error opening output file for writing: "<<outputFile<<std::endl;
                }
                cv::destroyAllWindows();
          }
      }
      else
      {
          std::cout<<"Could not open input list file for reading: "<<inputListFile<<std::endl;
      }
      inputlist_stream.close();
  }
  else if(std::strcmp(inputFile,"")!=0)
  {
      std::cout<<"Processing a single image\n";
      bool failed = true;
      //grab image, resize and flip
      frame = cv::imread(inputFile, CV_LOAD_IMAGE_COLOR);
      if(scale == 1)
      {
          im = frame; im_res = frame;
      }
    else 
          cv::resize(frame,im,cv::Size(scale*frame.cols,scale*frame.rows));

      cv::flip(im,im,1); 
      cv::cvtColor(im,gray,CV_BGR2GRAY);
      im_res = im;
    //track this image
    std::vector<int> wSize; if(failed)wSize = wSize2; else wSize = wSize1; 
    cv::Point* new_points;
    if(model.Track(gray,wSize,fpd,nIter,clamp,fTol,fcheck) == 0){
      int idx = model._clm.GetViewIdx(); failed = false;
      Draw(im,model._shape,con,model._clm._visi[idx]); 
      EditPointsAroundEye(im,model._shape,model._clm._visi[idx],new_points);
    }else{
      if(show){cv::Mat R(im,cvRect(0,0,150,50)); R = cv::Scalar(0,0,255);}
      model.FrameReset(); failed = true;
    }     
    if(new_points)
    {
//        print_points(new_points,model._shape,1);
//        print_points(new_points,model._shape);
//        int idx = model._clm.GetViewIdx();
//        DrawAnnotatedPoints(im_res,model._shape,model._clm._visi[idx],new_points);
//        cv::imshow("RESULTS", im_res);
//        cv::waitKey(0);
        
        // print results to file
        std::ofstream filestream;
        filestream.open(outputFile, std::ios::app);
        if(filestream.is_open())
        {
            filestream<<inputFile<<" ";
            for(int i = 0; i < SIZE_EYE_POINTS_ARRAY; i++)
            {
                filestream<<new_points[i].x<<" "<<new_points[i].y<<" ";
            }
            filestream<<std::endl;
            filestream.close();
        }
        else
            std::cout<<"Error opening output file for writing"<<std::endl;
    }
  }
  else
  {
    //loop until quit (i.e user presses ESC)
    bool failed = true;
    while(1){ 
        //grab image, resize and flip
        IplImage* I = cvQueryFrame(camera); if(!I)continue; frame = I;
        if(scale == 1)im = frame; 

        else cv::resize(frame,im,cv::Size(scale*frame.cols,scale*frame.rows));
        cv::flip(im,im,1); 
        cv::cvtColor(im,gray,CV_BGR2GRAY);
        //track this image
        std::vector<int> wSize; if(failed)wSize = wSize2; else wSize = wSize1; 
        if(model.Track(gray,wSize,fpd,nIter,clamp,fTol,fcheck) == 0){
        int idx = model._clm.GetViewIdx(); failed = false;
        Draw(im,model._shape,con,model._clm._visi[idx]); 
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
        
        //show image and check for user input
        cv::imshow("Face Tracker",im); 
        int c = cvWaitKey(10);
        if(c == 27)break; else if(char(c) == 'd')model.FrameReset();
    }
  }
  return 0;
}
//=============================================================================
