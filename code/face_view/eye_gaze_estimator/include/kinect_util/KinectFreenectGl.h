/* 
 * File:   KinectFreenectGl.h
 * Author: varsha
 *
 * Created on June 26, 2013, 11:32 AM
 */

#ifndef KINECTFREENECTGL_H
#define	KINECTFREENECTGL_H

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>
#include "libfreenect.h"
#include <common/common.hpp>
#include <pthread.h>

#if defined(__APPLE__)
#include <GLUT/glut.h>
#include <OpenGL/gl.h>
#include <OpenGL/glu.h>
#else
#include <GL/glut.h>
#include <GL/gl.h>
#include <GL/glu.h>
#endif
#include <math.h>

class KinectFreenectGl
{
public:
    KinectFreenectGl(int xres, int yres);
    int start();
    int stop();
    void * startGl(int, char **);
    void setRGBCallback(void (*cb)(uint8_t* ));
    void setDepthCallback(void (*cb)(uint16_t* ));
    static freenect_video_format requested_format;
    static freenect_video_format current_format;
    static freenect_resolution requested_resolution;
    static freenect_resolution current_resolution;
    static int got_rgb, got_depth;
private:
    pthread_t freenect_thread;
    int display_xres, display_yres;
    int window, g_argc;
    char **argv;
    
    static void depth_cb(freenect_device *dev, void *v_depth, uint32_t timestamp);
    static void rgb_cb(freenect_device *dev, void *v_rgb, uint32_t timestamp);
    static void *freenect_threadfunc(void* arg);
    
    void initGl(int, int);
};

static volatile int die;

static freenect_device* f_dev;
static freenect_context* f_ctx;

static pthread_mutex_t gl_backbuf_mutex;
static pthread_cond_t gl_frame_cond;

static void (*extRGBCb)(uint8_t* rgb);
static void (*extDepthCb)(uint16_t* rgb);

// back: owned by libfreenect (implicit for depth)
// mid: owned by callbacks, "latest frame ready"
// front: owned by GL, "currently being drawn"
extern uint8_t *depth_mid, *depth_front;
extern uint8_t *rgb_back, *rgb_mid, *rgb_front;
extern GLuint gl_depth_tex;
extern GLuint gl_rgb_tex;
extern uint16_t t_gamma[2048];

void resizeGlScene(int, int);
void keyPressed(unsigned char key, int x, int y);
void drawGlScene();    

#endif	/* KINECTFREENECTGL_H */

