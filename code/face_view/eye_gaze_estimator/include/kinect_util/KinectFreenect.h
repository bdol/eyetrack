#ifndef __KinectFreenect__
#define __KinectFreenect__

#include <iostream>
#include <sstream>
#include <unistd.h>

#include <pthread.h>

#include <opencv2/opencv.hpp>
#include <opencv2/highgui/highgui.hpp>
#include <opencv/cvaux.h>
#include <opencv2/imgproc/imgproc.hpp>
#include "libfreenect.h"

class KinectFreenect
{
public:
    KinectFreenect();
    int start();
    int stop();
    void setRGBCallback(void (*cb)(uint8_t* rgb));
    void setDepthCallback(void (*cb)(uint16_t* depth));

private:
    freenect_video_format requested_format;
    freenect_video_format current_format;
    freenect_resolution requested_resolution;
    freenect_resolution current_resolution;

    pthread_t fnkt_thread;
    
    static void depth_cb(freenect_device *dev, void *v_depth, uint32_t timestamp);
    static void rgb_cb(freenect_device *dev, void *v_rgb, uint32_t timestamp);
    static void *freenect_threadfunc(void* arg);

};

static volatile int die;
static pthread_mutex_t buf_mutex;
static pthread_cond_t frame_cond;

static freenect_device* f_dev;
static freenect_context* f_ctx;

static void (*extRGBCb)(uint8_t* rgb);
static void (*extDepthCb)(uint16_t* rgb);
#endif
