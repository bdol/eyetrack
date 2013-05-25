Calculate HoG features on the new transformed dataset of eye 
cropped images.
4 fold xval is performed by grouping subjects without separating any data 
within a specific subject folder to determine appropriate cost function 
value for the svm

9 models are trained; one for each board number.
For each image, the hog features for the right eye are concatenated with 
those calculated for the left eye.
The final prediction is that of the model with max confidence

third party libs used:
vlfeat (for hog calculation)
libsvm