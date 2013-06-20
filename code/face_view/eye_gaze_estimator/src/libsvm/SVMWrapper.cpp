#include <libsvm/SVMWrapper.h>

SVMWrapper::SVMWrapper(std::string fileName)
{
    max_nr_attr = 10000;
    x = (struct svm_node *) malloc(max_nr_attr*sizeof(struct svm_node));
    prob_estimates = (double *) malloc(3*sizeof(double));

    if ((model = svm_load_model(fileName.c_str()))==0) {
        fprintf(stderr,"can't open model file train.model\n");
        exit(1);
    } else {
      printf("Successfully loaded SVM model.\n");
    }
}

double* SVMWrapper::predict(cv::Mat &left, cv::Mat &right)
{
    if (model == NULL) {
        return NULL;
    }

    double predict_label;

    int svm_type=svm_get_svm_type(model);
	int nr_class=svm_get_nr_class(model);

    int *labels=(int *) malloc(nr_class*sizeof(int));
    svm_get_labels(model,labels);

    int i=0;
    for (int j=0; j<left.cols; j++) {
        for (int k=0; k<left.rows; k++) {
            x[i].index = i;
            x[i].value = left.at<float>(k, j);
            i++;
        }
    }

    for (int j=0; j<right.cols; j++) {
        for (int k=0; k<right.rows; k++) {
            x[i].index = i;
            x[i].value = right.at<float>(k, j);
            i++;
        }
    }

    predict_label = svm_predict_probability(model,x, prob_estimates);

    free(labels);

    return prob_estimates;
}

