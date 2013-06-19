#include <kinect_util/KinectFreenect.h>

KinectFreenect::KinectFreenect() {
    die = 0;

    requested_format = FREENECT_VIDEO_RGB;
    current_format = FREENECT_VIDEO_RGB;
    requested_resolution = FREENECT_RESOLUTION_HIGH;
    current_resolution = FREENECT_RESOLUTION_HIGH;

    pthread_mutex_init(&buf_mutex, NULL);
    pthread_cond_init(&frame_cond, NULL);
}

void KinectFreenect::setRGBCallback(void (*cb)(uint8_t* rgb)) {
    extRGBCb = cb;
}

void KinectFreenect::setDepthCallback(void (*cb)(uint16_t* rgb)) {
    extDepthCb = cb;
}

void KinectFreenect::depth_cb(freenect_device *dev, void *v_depth, uint32_t timestamp) {
    pthread_mutex_lock(&buf_mutex);
    uint16_t *depth = (uint16_t*)v_depth;

    // Send the data to the application's callback function
    if (extDepthCb != NULL) {
        extDepthCb(depth);
    }
     
    pthread_cond_signal(&frame_cond);
    pthread_mutex_unlock(&buf_mutex);
}
 
void KinectFreenect::rgb_cb(freenect_device *dev, void *v_rgb, uint32_t timestamp) {
    pthread_mutex_lock(&buf_mutex);

    uint8_t *rgb = (uint8_t*)v_rgb;

    // Send the data to the application's callback function
    if (extRGBCb != NULL) {
        extRGBCb(rgb);
    }
     
    pthread_cond_signal(&frame_cond);
    pthread_mutex_unlock(&buf_mutex);
}

void* KinectFreenect::freenect_threadfunc(void* arg) {
    while(!die && freenect_process_events(f_ctx) >= 0 ) {}
    return NULL;
}


int KinectFreenect::start() {
    if (freenect_init(&f_ctx, NULL) < 0) {
        printf("freenect_init() failed\n");
        return 1;
    }

    int nr_devices = freenect_num_devices(f_ctx);

    int user_device_number = 0;
    if (freenect_open_device(f_ctx, &f_dev, user_device_number) < 0) {
        printf("Could not open device.\n");
        return 1;
    }

    freenect_set_led(f_dev, LED_RED);
    freenect_set_depth_callback(f_dev, KinectFreenect::depth_cb);
    freenect_set_video_callback(f_dev, KinectFreenect::rgb_cb);
    freenect_set_video_mode(f_dev, freenect_find_video_mode(current_resolution, current_format));
    freenect_set_depth_mode(f_dev, freenect_find_depth_mode(FREENECT_RESOLUTION_MEDIUM, FREENECT_DEPTH_11BIT));

    freenect_start_depth(f_dev);
    freenect_start_video(f_dev);
    
    int res;
    res = pthread_create(&fnkt_thread, NULL, freenect_threadfunc, NULL);
    if (res) {
        printf("pthread_create failed\n");
        return 1;
    }

    int status = 0;
    while (!die && status >= 0) {
        char k = cvWaitKey(5);
        if( k == 27 ) {
            die = 1;
            break;
        }
    }


    return 0;
}

int KinectFreenect::stop() {
    die = 1;
    freenect_stop_depth(f_dev);
    freenect_stop_video(f_dev);

    freenect_close_device(f_dev);
    freenect_shutdown(f_ctx);

    pthread_join(fnkt_thread, NULL);

    return 0;
}
