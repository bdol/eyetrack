#pragma once

#include <opencv2/core/core.hpp>

#define WINDOW_FLAGS (CV_WINDOW_NORMAL | CV_WINDOW_KEEPRATIO | CV_GUI_EXPANDED)

/////////////////////////////////////////////////
// functions for you to complete in hw4.cpp
/////////////////////////////////////////////////
extern cv::Mat minimizeAx(const cv::Mat &A);
extern cv::Vec3d fitLine(const cv::Mat &im, size_t n);
extern cv::Vec3d findIntersection(const cv::Mat &L);
extern cv::Mat computeProjTransfo(const cv::Vec3d &vx,
    const cv::Vec3d &vy, const cv::Point &x00, const cv::Point &x11);
extern cv::Mat rectifyImage(const cv::Mat &A, const cv::Mat &im,
    size_t N);

extern cv::Mat fitHomography(const cv::Mat &X1, const cv::Mat &X2);
extern cv::Mat findCorrespAndFitHomography(const cv::Mat &im1,
    const cv::Mat &im2, const size_t N);

/////////////////////////////////////////////////
// helper functions implemented for your benefit
// in hw4_helpers.cpp
/////////////////////////////////////////////////
extern cv::Point getClick(const std::string &winname, const cv::Mat &im);
extern cv::Vec3d getVanishingPoint(const cv::Mat &im,
    size_t numPointsPerLine = 6,
    size_t numLinesPerVanishingPoint = 6);
extern void drawCross(cv::Mat &im, const cv::Point &pt, size_t sz=5);
