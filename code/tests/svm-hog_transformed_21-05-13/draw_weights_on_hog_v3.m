function [imhog_pos imhog_neg] = draw_weights_on_hog_v3(training_row, weights, ind_rowvec_to_hog, num_orientation, size_hog)

% POSITIVE WEIGHTS
pos_weights = weights;
pos_weights(pos_weights<0) = 0;
% weight the hog desciptor by the weights learned
pos_weighted_hog = training_row.*pos_weights';
weighted_rendered_hog = zeros(size_hog);
weighted_rendered_hog(ind_rowvec_to_hog) = pos_weighted_hog;
imhog_pos = vl_hog('render', single(weighted_rendered_hog), 'numOrientations', num_orientation) ;

% NEGATIVE WEIGHTS
neg_weights = weights;
neg_weights(neg_weights>0) = 0;
% weight the hog desciptor by the weights learned
neg_weighted_hog = training_row.*neg_weights';
weighted_rendered_hog = zeros(size_hog);
weighted_rendered_hog(ind_rowvec_to_hog) = neg_weighted_hog;
imhog_neg = vl_hog('render', single(weighted_rendered_hog), 'numOrientations', num_orientation) ;