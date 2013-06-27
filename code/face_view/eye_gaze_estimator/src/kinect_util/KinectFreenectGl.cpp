#include <kinect_util/KinectFreenectGl.h>

freenect_video_format KinectFreenectGl::requested_format = FREENECT_VIDEO_RGB;
freenect_video_format KinectFreenectGl::current_format = FREENECT_VIDEO_RGB;
freenect_resolution KinectFreenectGl::requested_resolution = FREENECT_RESOLUTION_HIGH;
freenect_resolution KinectFreenectGl::current_resolution = FREENECT_RESOLUTION_HIGH;
int KinectFreenectGl::got_rgb = 0;
int KinectFreenectGl::got_depth = 0;
// back: owned by libfreenect (implicit for depth)
// mid: owned by callbacks, "latest frame ready"
// front: owned by GL, "currently being drawn"
uint8_t *depth_mid = (uint8_t*)malloc(DEPTH_XRES*DEPTH_YRES*3);
uint8_t *depth_front = (uint8_t*)malloc(DEPTH_XRES*DEPTH_YRES*3);
uint8_t *rgb_back =  (uint8_t*)malloc(IMAGE_XRES*IMAGE_YRES*3);
uint8_t *rgb_mid = (uint8_t*)malloc(IMAGE_XRES*IMAGE_YRES*3);
uint8_t *rgb_front = (uint8_t*)malloc(IMAGE_XRES*IMAGE_YRES*3);
GLuint gl_depth_tex;
GLuint gl_rgb_tex;
uint16_t t_gamma[2048];

KinectFreenectGl::KinectFreenectGl(int xres, int yres) {
    pthread_mutex_init(&gl_backbuf_mutex, NULL);
    pthread_cond_init(&gl_frame_cond, NULL);
    die = 0;
    display_xres = xres;
    display_yres = yres;
}

void resizeGlScene(int Width, int Height) {
    glViewport(0, 0, Width, Height);
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    // left right bottom top znear zfar
    // bottom left - (0,0) invert the bottom and top....opencv -> opengl
    glOrtho(0, Width, Height, 0, -1.0f, 1.0f);
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();
}

void KinectFreenectGl::initGl(int Width, int Height) {
    glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
    glClearDepth(1.0);
    glDepthFunc(GL_LESS);
    glDepthMask(GL_FALSE);
    glDisable(GL_DEPTH_TEST);
    glDisable(GL_BLEND);
    glDisable(GL_ALPHA_TEST);
    glEnable(GL_TEXTURE_2D);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glShadeModel(GL_FLAT);

    glGenTextures(1, &gl_depth_tex);
    glBindTexture(GL_TEXTURE_2D, gl_depth_tex);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);

    glGenTextures(1, &gl_rgb_tex);
    glBindTexture(GL_TEXTURE_2D, gl_rgb_tex);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);

    resizeGlScene(Width, Height);
}

void * KinectFreenectGl::startGl(int argc, char **argv) {
    printf("GL thread\n");

    glutInit(&argc, argv);

    glutInitDisplayMode(GLUT_RGBA | GLUT_DOUBLE | GLUT_ALPHA | GLUT_DEPTH);
    glutInitWindowSize(display_xres, display_yres);
    glutInitWindowPosition(0, 0);

    window = glutCreateWindow("LibFreenect");

    glutDisplayFunc(&drawGlScene);
    glutIdleFunc(&drawGlScene);
    glutReshapeFunc(&resizeGlScene);
    glutKeyboardFunc(&keyPressed);

    initGl(display_xres, display_yres);

    glutMainLoop();

    return NULL;
}

void KinectFreenectGl::depth_cb(freenect_device *dev, void *v_depth, uint32_t timestamp) {
    int i;
    uint16_t *depth = (uint16_t*) v_depth;

    pthread_mutex_lock(&gl_backbuf_mutex);
    for (i = 0; i < 640 * 480; i++) {
        int pval = t_gamma[depth[i]];
        int lb = pval & 0xff;
        switch (pval >> 8) {
            case 0:
                depth_mid[3 * i + 0] = 255;
                depth_mid[3 * i + 1] = 255 - lb;
                depth_mid[3 * i + 2] = 255 - lb;
                break;
            case 1:
                depth_mid[3 * i + 0] = 255;
                depth_mid[3 * i + 1] = lb;
                depth_mid[3 * i + 2] = 0;
                break;
            case 2:
                depth_mid[3 * i + 0] = 255 - lb;
                depth_mid[3 * i + 1] = 255;
                depth_mid[3 * i + 2] = 0;
                break;
            case 3:
                depth_mid[3 * i + 0] = 0;
                depth_mid[3 * i + 1] = 255;
                depth_mid[3 * i + 2] = lb;
                break;
            case 4:
                depth_mid[3 * i + 0] = 0;
                depth_mid[3 * i + 1] = 255 - lb;
                depth_mid[3 * i + 2] = 255;
                break;
            case 5:
                depth_mid[3 * i + 0] = 0;
                depth_mid[3 * i + 1] = 0;
                depth_mid[3 * i + 2] = 255 - lb;
                break;
            default:
                depth_mid[3 * i + 0] = 0;
                depth_mid[3 * i + 1] = 0;
                depth_mid[3 * i + 2] = 0;
                break;
        }
    }
    // Send the data to the application's callback function
    if (extDepthCb != NULL) {
        extDepthCb(depth);
    }
    got_depth++;
    pthread_cond_signal(&gl_frame_cond);
    pthread_mutex_unlock(&gl_backbuf_mutex);
}

void KinectFreenectGl::rgb_cb(freenect_device *dev, void *rgb, uint32_t timestamp) {
    pthread_mutex_lock(&gl_backbuf_mutex);

    // swap buffers
    assert(rgb_back == rgb);
    rgb_back = rgb_mid;
    freenect_set_video_buffer(dev, rgb_back);
    rgb_mid = (uint8_t*) rgb;
    
    // Send the data to the application's callback function
    if (extRGBCb != NULL) {
        extRGBCb((uint8_t*)rgb);
    }

    got_rgb++;
    pthread_cond_signal(&gl_frame_cond);
    pthread_mutex_unlock(&gl_backbuf_mutex);
}

void *KinectFreenectGl::freenect_threadfunc(void* arg) {
    while (!die && freenect_process_events(f_ctx) >= 0) {}
    return NULL;
}

int KinectFreenectGl::start() {
    int i;
	for (i=0; i<2048; i++) {
		float v = i/2048.0;
		v = powf(v, 3)* 6;
		t_gamma[i] = v*6*256;
	}

    
    if (freenect_init(&f_ctx, NULL) < 0) {
        printf("freenect_init() failed\n");
        return 1;
    }

    freenect_select_subdevices(f_ctx, (freenect_device_flags) (FREENECT_DEVICE_MOTOR | FREENECT_DEVICE_CAMERA));

    int nr_devices = freenect_num_devices(f_ctx);
    printf("Number of devices found: %d\n", nr_devices);

    int user_device_number = 0;
    if (nr_devices < 1) {
        freenect_shutdown(f_ctx);
        return 1;
    }

    if (freenect_open_device(f_ctx, &f_dev, user_device_number) < 0) {
        printf("Could not open device\n");
        freenect_shutdown(f_ctx);
        return 1;
    }

    freenect_set_tilt_degs(f_dev, 10);
    freenect_set_led(f_dev, LED_RED);
    freenect_set_depth_callback(f_dev, KinectFreenectGl::depth_cb);
    freenect_set_video_callback(f_dev, KinectFreenectGl::rgb_cb);
    freenect_set_video_mode(f_dev, freenect_find_video_mode(current_resolution, current_format));
    freenect_set_depth_mode(f_dev, freenect_find_depth_mode(FREENECT_RESOLUTION_MEDIUM, FREENECT_DEPTH_11BIT));
    freenect_set_video_buffer(f_dev, rgb_back);

    freenect_start_depth(f_dev);
    freenect_start_video(f_dev);

    int res;
    res = pthread_create(&freenect_thread, NULL, freenect_threadfunc, NULL);
    if (res) {
        printf("pthread_create failed\n");
        freenect_shutdown(f_ctx);
        return 1;
    }
}

int KinectFreenectGl::stop() {
    printf("\nshutting down streams...");
    die = 1;
    freenect_stop_depth(f_dev);
    freenect_stop_video(f_dev);

    freenect_close_device(f_dev);
    freenect_shutdown(f_ctx);

    pthread_join(KinectFreenectGl::freenect_thread, NULL);
    glutDestroyWindow(window);
    free(depth_mid);
    free(depth_front);
    free(rgb_back);
    free(rgb_mid);
    printf("-- done!\n");
    // Not pthread_exit because OSX leaves a thread lying around and doesn't exit
    exit(0);

}

void KinectFreenectGl::setRGBCallback(void (*cb)(uint8_t* rgb)) {
    extRGBCb = cb;
}

void KinectFreenectGl::setDepthCallback(void (*cb)(uint16_t* rgb)) {
    extDepthCb = cb;
}