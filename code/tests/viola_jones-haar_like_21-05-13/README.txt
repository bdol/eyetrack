Haar cascades are learnt using opencv's haar training function. The inputs
to this process are both positive and negative examples.
18 haar cascades are trained; one for each board number and for each eye
Positive examples include all left or right eye crops for a particular 
board number
Negative examples include all left or right eye crops for every other board
 number

generate_samples.m prepares the data before training.
train_haar_cascades.pl runs the opencv training