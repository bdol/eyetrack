//
//  MyFreenectDevice.h
//  TableTop
//
//  Created by Brian Dolhansky on 5/9/13.
//  Copyright (c) 2013 Brian Dolhansky. All rights reserved.
//

#ifndef __TableTop__MyFreenectDevice__
#define __TableTop__MyFreenectDevice__

#include <iostream>
#include <libfreenect.hpp>
#include <vector>
#include <opencv2/opencv.hpp>
#include <opencv2/highgui/highgui.hpp>
#include <opencv/cvaux.h>
#include <opencv2/imgproc/imgproc.hpp>
#include "MutexWrapper.h"

using namespace cv;
class MyFreenectDevice : public Freenect::FreenectDevice {
public:
	MyFreenectDevice(freenect_context *_ctx, int _index);
    
	void VideoCallback(void* _rgb, uint32_t timestamp);
	void DepthCallback(void* _depth, uint32_t timestamp);
    
	bool getVideo(Mat& output);
	bool getDepth(Mat& output);
    
private:
	std::vector<uint8_t> m_buffer_depth;
	std::vector<uint8_t> m_buffer_rgb;
	std::vector<uint16_t> m_gamma;
	Mat depthMat;
	Mat rgbMat;
	Mat ownMat;
	MutexWrapper m_rgb_mutex;
	MutexWrapper m_depth_mutex;
	bool m_new_rgb_frame;
	bool m_new_depth_frame;
};

#endif /* defined(__TableTop__MyFreenectDevice__) */
