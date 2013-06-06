Dataset used:
Cropped eyes after running correction for IM_*_1 images. The dataset was 
also cleaned up on the first run and subsequently loaded using 
load_lrc_cropped_eyes(<path_to_corrected_crops>). The load function 
automatically discards bad images according to files present in 
../../data_processing/, unless other bad-image files are specified

Features used:
HoG with cellsize 8
the number of orientations is either 9 0r 21 based on xval results

Classifier used: 
Linear svm with cost value decided by xval results

Third party libs used:
vlfeat (for hog calculation)
libsvm