Haar cascades are learnt using opencv's haar training function. The inputs
to this process are both positive and negative examples.
9 haar cascades are trained; one for each board number
Positive examples include all eye crops for a particular board number.
negative examples include all eye crops for every other board number.

generate_samples.m prepares the data before opencv training
train_haar_cascades.pl runs the opencv training