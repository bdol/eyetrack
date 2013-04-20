Calculate HoG features on the reduced dataset of eye cropped images.
5 fold xval is performed by grouping subjects without separating any data 
within a specific subject folder.

Currently, two experiments are run:
1. linear multiclass svm
2. two class (1 vs rest) linear svm

third party libs used:
vlfeat (for hog calculation)
libsvm