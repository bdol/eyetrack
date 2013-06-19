#include <FaceTracker/FaceTrackerWrapper.h>

FaceTrackerWrapper::FaceTrackerWrapper() {
    wSize1.push_back(7);
    wSize2.push_back(11); wSize2.push_back(9); wSize2.push_back(7);

    nIter = 5;
    clamp = 3;
    fTol = 0.01;
    fpd = -1;

    model = new FACETRACKER::Tracker("../model/face2.tracker");
    tri=FACETRACKER::IO::LoadTri("../model/face.tri");
    con=FACETRACKER::IO::LoadCon("../model/face.con");
    
    failed = true;
    fcheck = false;

    bb_width = 100;
    bb_height = 50;
}

int FaceTrackerWrapper::updateBoundingBoxes() {
    cv::Mat shape = model->_shape;
    int idx = model->_clm.GetViewIdx();
    cv::Mat visi = model->_clm._visi[idx];

    int n = shape.rows/2;
    double n_points_per_eye = 6.0;

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
    l_centroid = cv::Point(lx, ly);

    // Compute right eye centroid
    double rx, ry = 0.0;
    for (int i=37; i<=42; i++) {
        rx += (double)(shape.at<double>(con.at<int>(0,i),0));
        ry += (double)(shape.at<double>(con.at<int>(0,i)+n,0));
    }
    rx /= n_points_per_eye;
    ry /= n_points_per_eye;
    r_centroid = cv::Point(rx, ry);

    if (rx < 0 || ry < 0 || lx < 0 || ly < 0) {
        return 1;
    }

    lb1 = cv::Point(l_centroid.x - bb_width/2.0, l_centroid.y - bb_height/2.0);
    lb2 = cv::Point(l_centroid.x + bb_width/2.0, l_centroid.y + bb_height/2.0);
    rb1 = cv::Point(r_centroid.x - bb_width/2.0, r_centroid.y - bb_height/2.0);
    rb2 = cv::Point(r_centroid.x + bb_width/2.0, r_centroid.y + bb_height/2.0);
    
    return 0;
}

int FaceTrackerWrapper::cropEyes(cv::Mat &queryIm) {
    double lx = 1280-l_centroid.x;
    double rx = 1280-r_centroid.x;
    
    cv::Rect left_eye_rect = cv::Rect(lx-bb_width/2.0, l_centroid.y-bb_height/2.0, bb_width, bb_height);
    cv::Mat left_eye = queryIm(left_eye_rect).clone();
    cvtColor(left_eye, leftEyeNorm, CV_RGB2GRAY);
    normalize(leftEyeNorm, leftEyeNorm, 0, 1, cv::NORM_MINMAX, CV_32F);

    cv::Rect right_eye_rect = cv::Rect(rx-bb_width/2.0, r_centroid.y-bb_height/2.0, bb_width, bb_height);
    cv::Mat right_eye = queryIm(right_eye_rect).clone();
    cvtColor(right_eye, rightEyeNorm, CV_RGB2GRAY);
    normalize(rightEyeNorm, rightEyeNorm, 0, 1, cv::NORM_MINMAX, CV_32F);

    return 0;
}

int FaceTrackerWrapper::track(cv::Mat &queryIm) {
    frame = queryIm.clone();
    im = frame; // TODO: this may not be necessary...
    
    cv::flip(im,im,1); 
    cv::cvtColor(im,gray,CV_BGR2GRAY);

    std::vector<int> wSize; 
    if(failed) {
        wSize = wSize2;
    } else {
        wSize = wSize1;
    }

    if(model->Track(gray, wSize, fpd, nIter, clamp, fTol, fcheck) == 0){
      int idx = model->_clm.GetViewIdx(); 
      failed = false;
      updateBoundingBoxes();
      cropEyes(queryIm);

      return 0;
    } else {
      model->FrameReset(); 
      failed = true;
      return 1;
    }

}

int FaceTrackerWrapper::drawEyeBoxes(cv::Mat &queryIm, bool flip) {
    if (failed) {
        return 1;
    }

    cv::Scalar c;
    c = CV_RGB(0, 255, 0);

    cv::Point lb1f = lb1;
    cv::Point lb2f = lb2;
    cv::Point rb1f = rb1;
    cv::Point rb2f = rb2;
    if (!flip) { // We flipped the image for FaceTracker for some reason, so flip it back
        lb1f.x = 1280-lb1f.x;
        lb2f.x = 1280-lb2f.x;
        rb1f.x = 1280-rb1f.x;
        rb2f.x = 1280-rb2f.x;
    }

    cv::rectangle(queryIm, lb1f, lb2f, c);
    cv::rectangle(queryIm, rb1f, rb2f, c);

    return 0;
}

int FaceTrackerWrapper::getCroppedEyes(cv::Mat &leftEye, cv::Mat &rightEye) {
    if (failed) {
        return 1;
    }

    leftEye = leftEyeNorm.clone();
    rightEye = rightEyeNorm.clone();

    return 0;
}
