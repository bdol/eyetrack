//
//  main.cpp
//  ImagesFromOni
//
//  Created by Brian Dolhansky on 5/30/13.
//  Copyright (c) 2013 Brian Dolhansky. All rights reserved.
//

#include <iostream>
#include <XnOpenNI.h>
#include <XnLog.h>
#include <XnCppWrapper.h>
#include <XnFPSCalculator.h>
#include <opencv2/opencv.hpp>
#include <opencv2/highgui/highgui.hpp>
#include <opencv/cvaux.h>
#include <opencv2/imgproc/imgproc.hpp>
#include <fstream>

using namespace xn;
using namespace std;

int main(int argc, const char * argv[])
{

//    string fName = "/Users/bdol/code/eyetrack_data/video_b/Captured_4.oni";
//    string outDir = "/Users/bdol/code/eyetrack_data/video/Brian_30-05-2013/4/";
    
    string vidListFileName = "/Users/bdol/code/eyetrack_data/video/video_list";
    ifstream infile(vidListFileName.c_str());;
    string line;
    if (infile.is_open()) {
        string fName, outDir;
        while (infile.good()) {
            getline(infile, line);
            int delimPos = line.find(",");
            fName = line.substr(0, delimPos);
            outDir = line.substr(delimPos+1, line.length());
            mkdir(outDir.c_str(), S_IRWXU);
            
            cout << "Processing " << fName << endl;
            cout << "Saving in " << outDir << endl;
            Context context;
            context.Init();
            Player player;
            context.OpenFileRecording(fName.c_str(), player);
            player.SetRepeat(false);

            ImageGenerator imageGenerator;
            imageGenerator.Create(context);
            DepthGenerator depthGenerator;
            depthGenerator.Create(context);

            XnUInt32 numRGBFrames, numDepthFrames;
            player.GetNumFrames(imageGenerator.GetName(), numRGBFrames);
            cout << "Found " << numRGBFrames << " RGB frames." << endl;
            player.GetNumFrames(depthGenerator.GetName(), numDepthFrames);
            cout << "Found " << numDepthFrames << " depth frames." << endl;
            int numFrames = min(numRGBFrames, numDepthFrames);
            cout << "Saving " << numFrames << " RGB and Depth frames." << endl;

            // Set up RGB image
            XnMapOutputMode mapMode;
            imageGenerator.GetMapOutputMode(mapMode);
            IplImage* rgbImage = cvCreateImage(cvSize(mapMode.nXRes, mapMode.nYRes), IPL_DEPTH_8U, 3);
            // Set up depth image
            depthGenerator.GetMapOutputMode(mapMode);
            IplImage* depthImage = cvCreateImage(cvSize(mapMode.nXRes, mapMode.nYRes), IPL_DEPTH_16U, 1);

            context.StartGeneratingAll();
            for (int i=0; i<numFrames; ++i) {
                // Read and save RGB
                imageGenerator.WaitAndUpdateData();
                xnOSMemCopy(rgbImage->imageData, imageGenerator.GetRGB24ImageMap(), rgbImage->imageSize);
                cvCvtColor(rgbImage, rgbImage, CV_RGB2BGR);
                stringstream s_rgb;
                s_rgb << outDir << "rgb_" << i << ".png";
                cvSaveImage(s_rgb.str().c_str(), rgbImage);

                // Read and save depth
                depthGenerator.WaitAndUpdateData();
                xnOSMemCopy(depthImage->imageData, depthGenerator.GetDepthMap(), depthImage->imageSize);
                stringstream s_depth;
                s_depth << outDir << "depth_" << i << ".png";
                cvSaveImage(s_depth.str().c_str(), depthImage);
            }

            // Clean up the OpenNI context
            context.StopGeneratingAll();
            context.Release();

        }
        infile.close();
    }
    
    
    return 0;
}

