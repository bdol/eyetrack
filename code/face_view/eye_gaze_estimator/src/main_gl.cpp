/* 
 * File:   main.cpp
 * Author: varsha
 *
 * Created on June 26, 2013, 11:22 AM
 */

/*
 * This file is part of the OpenKinect Project. http://www.openkinect.org
 *
 * Copyright (c) 2010 individual OpenKinect contributors. See the CONTRIB file
 * for details.
 *
 * This code is licensed to you under the terms of the Apache License, version
 * 2.0, or, at your option, the terms of the GNU General Public License,
 * version 2.0. See the APACHE20 and GPL2 files for the text of the licenses,
 * or the following URLs:
 * http://www.apache.org/licenses/LICENSE-2.0
 * http://www.gnu.org/licenses/gpl-2.0.txt
 *
 * If you redistribute this file in source form, modified or unmodified, you
 * may:
 *   1) Leave this header intact and distribute it under the same terms,
 *      accompanying it with the APACHE20 and GPL20 files, or
 *   2) Delete the Apache 2.0 clause and accompany it with the GPL2 file, or
 *   3) Delete the GPL v2 clause and accompany it with the APACHE20 file
 * In all cases you must keep the copyright notice intact and include a copy
 * of the CONTRIB file.
 *
 * Binary distributions must follow the binary distribution requirements of
 * either License.
 */

#include <iostream>
#include <sstream>
#include <unistd.h>
#include <pthread.h>

#include <opencv2/opencv.hpp>
#include <opencv2/highgui/highgui.hpp>
#include <opencv/cvaux.h>
#include <opencv2/imgproc/imgproc.hpp>

#include <common/common.hpp>
#include "libfreenect.h"
#include <FaceTracker/Tracker.h>
#include <kinect_util/KinectFreenectGl.h>
#include <FaceTracker/FaceTrackerWrapper.h>
#include <libsvm/SVMWrapper.h>
#include <socket/Socket.h>
#include <head_pose/head_pose.hpp>


// Use this to set the size of the display window
#define DISPLAY_WINDOW_XRES 640
#define DISPLAY_WINDOW_YRES 512

using namespace std;
using namespace cv;

KinectFreenectGl* kinect;
Mat depthMat(Size(DEPTH_XRES, DEPTH_YRES), CV_16UC1);
Mat rgbMat(Size(IMAGE_XRES, IMAGE_YRES), CV_8UC3);
Mat leftEye, rightEye;

FaceTrackerWrapper* faceTracker;
SVMWrapper* svm;
bool facetracker_status;
Mat tempMat;

void drawGlScene() {
    pthread_mutex_lock(&gl_backbuf_mutex);

    freenect_video_format current_format = KinectFreenectGl::current_format;
    freenect_video_format requested_format = KinectFreenectGl::requested_format;
    int got_rgb = KinectFreenectGl::got_rgb;
    int got_depth = KinectFreenectGl::got_depth;

    // When using YUV_RGB mode, RGB frames only arrive at 15Hz, so we shouldn't force them to draw in lock-step.
    // However, this is CPU/GPU intensive when we are receiving frames in lockstep.
    if (current_format == FREENECT_VIDEO_YUV_RGB) {
        while (!got_depth && !got_rgb) {
            pthread_cond_wait(&gl_frame_cond, &gl_backbuf_mutex);
        }
    } else {
        while ((!got_depth || !got_rgb) && requested_format != current_format) {
            pthread_cond_wait(&gl_frame_cond, &gl_backbuf_mutex);
        }
    }

    if (requested_format != current_format) {
        pthread_mutex_unlock(&gl_backbuf_mutex);
        return;
    }

    uint8_t *tmp;

    // if facetracker has found eyes and updated the bbox and prob values, 
    // render the updated rgbMat instead of rgb_front
    if (got_rgb & facetracker_status) {
        int from_to[] = {0, 2, 1, 1, 2, 0};
        mixChannels(&rgbMat, 1, &tempMat, 1, from_to, 3);
        //        cvtColor(rgbMat, rgbMat, CV_RGB2BGR);
        rgb_front = (uint8_t*) tempMat.data;
        KinectFreenectGl::got_rgb = 0;
    }

    pthread_mutex_unlock(&gl_backbuf_mutex);

        glBindTexture(GL_TEXTURE_2D, gl_rgb_tex);
        if (current_format == FREENECT_VIDEO_RGB || current_format == FREENECT_VIDEO_YUV_RGB)
            glTexImage2D(GL_TEXTURE_2D, 0, 3, IMAGE_XRES, IMAGE_YRES, 0, GL_RGB, GL_UNSIGNED_BYTE, rgb_front);
        else
            glTexImage2D(GL_TEXTURE_2D, 0, 1, IMAGE_XRES, IMAGE_YRES, 0, GL_LUMINANCE, GL_UNSIGNED_BYTE, rgb_front + IMAGE_XRES * 4);
    
        glBegin(GL_TRIANGLE_FAN);
            glColor4f(1.0f, 1.0f, 1.0f, 1.0f);
            glTexCoord2f(0, 0);
            glVertex3f(0, 0, 0);
            glTexCoord2f(1, 0);
            glVertex3f(DISPLAY_WINDOW_XRES, 0, 0);
            glTexCoord2f(1, 1);
            glVertex3f(DISPLAY_WINDOW_XRES, DISPLAY_WINDOW_YRES, 0);
            glTexCoord2f(0, 1);
            glVertex3f(0, DISPLAY_WINDOW_YRES, 0);
        glEnd();


    if (got_depth) {
        get_head_pose_estimate(depthMat);
        KinectFreenectGl::got_depth = 0;
    }
    glutSwapBuffers();
}

void updateDrawnPredictions(double* prob_estimates) {
    if (prob_estimates != NULL) {
        for (int i = 0; i < 3; i++) {
            stringstream predVal;
            int predNum = i + 1;
            switch (predNum) {
                    double p;
                case 1:
                    p = prob_estimates[i];
                    predVal << "L: " << p;
                    putText(rgbMat, predVal.str(), Point(30, 30), CV_FONT_HERSHEY_PLAIN, 1, Scalar(255, 255, 255));
                    rectangle(rgbMat, Point(30, 40), Point(p * 300.0 + 30, 50), Scalar(255, 0, 0), CV_FILLED);
                    break;
                case 2:
                    p = prob_estimates[i];
                    predVal << "R: " << p;
                    rectangle(rgbMat, Point(30, 120), Point(p * 300.0 + 30, 130), Scalar(0, 255, 0), CV_FILLED);
                    putText(rgbMat, predVal.str(), Point(30, 110), CV_FONT_HERSHEY_PLAIN, 1, Scalar(255, 255, 255));
                    break;
                case 3:
                    p = prob_estimates[i];
                    predVal << "C: " << p;
                    rectangle(rgbMat, Point(30, 80), Point(p * 300.0 + 30, 90), Scalar(0, 0, 255), CV_FILLED);
                    putText(rgbMat, predVal.str(), Point(30, 70), CV_FONT_HERSHEY_PLAIN, 1, Scalar(255, 255, 255));
                    break;
            }
        }
        facetracker_status = true;
    } else
        facetracker_status = false;
}

void keyPressed(unsigned char key, int x, int y) {
    if (key == 27) {
        // initiate a shutdown
        kinect->stop();
    }
}

void rgbCallback(uint8_t* rgb) {
    // Get the data from the Kinect
    memcpy(rgbMat.data, rgb, IMAGE_XRES * IMAGE_YRES * 3 * sizeof (uint8_t));
    cvtColor(rgbMat, rgbMat, CV_BGR2RGB);
    if ((faceTracker->track(rgbMat)) == 0) { // Successfully found face
        faceTracker->drawEyeBoxes(rgbMat, false);

        faceTracker->getCroppedEyes(leftEye, rightEye);

        double* vals = svm->predict(leftEye, rightEye);
        updateDrawnPredictions(vals);

        // Send the predictions to the server
        // TODO: change this so we're not restarting the socket every time
        //        Socket* mySocket = new Socket();
        //        mySocket->startClient("192.168.1.104");
        //        std::stringstream ss;
        //        ss << vals[0] << " " << vals[1] << " " << vals[2] << endl;
        //        mySocket->clientSendMessage(ss.str());
        //        mySocket->stopClient();
    }
}

void depthCallback(uint16_t* depth) {
    memcpy(depthMat.data, depth, DEPTH_YRES * DEPTH_XRES * sizeof (uint16_t));
}

int main(int argc, char **argv) {
    // Set up FaceTracker
    faceTracker = new FaceTrackerWrapper();

    // Set up SVM
    svm = new SVMWrapper("../model/svm_trained.model");

    // Initialise head pose estimator
    init_headpose();

    tempMat = Mat(IMAGE_YRES, IMAGE_XRES, CV_8UC3);

    // Set up Kinect
    kinect = new KinectFreenectGl(DISPLAY_WINDOW_XRES, DISPLAY_WINDOW_YRES);
    kinect->start();
    kinect->setRGBCallback(rgbCallback);
    kinect->setDepthCallback(depthCallback);
    // OS X requires GLUT to run on the main thread
    kinect->startGl(argc, argv);


    return 0;
}


