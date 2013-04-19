This test extracts pb data from the cropped images using contrast gradients and
displays it for a set of images contained within the 'images' folder (or
elsewhere, depending on the path you specify). 
To use the test, make sure that you change the 'subj_names' cell variable in the
file display_feats.m

It refers to a third party lib 'segbench' for  the pb code currently in the repo
at eyetrack/third_party_libs/segbench
We might want to think about having copies of external libraries on local
machines only.

