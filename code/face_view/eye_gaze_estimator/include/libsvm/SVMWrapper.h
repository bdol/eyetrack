#ifndef __SVMWrapper__
#define __SVMWrapper__

#include <stdio.h>
#include <string>
#include <opencv/highgui.h>
#include <libsvm/svm.h>

class SVMWrapper
{
public:
    SVMWrapper(std::string fileName);
    double* predict(cv::Mat &left, cv::Mat &right);

private:
    struct svm_node* x;
    int max_nr_attr;
    double* prob_estimates;
    svm_model* model;
};


#endif
