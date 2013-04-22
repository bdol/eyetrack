function draw_weights_on_hog_v2(eye_image, training_row, weights, ind_rowvec_to_hog, num_orientation, size_hog, filename)

% POSITIVE WEIGHTS
pos_weights = weights;
pos_weights(pos_weights<0) = 0;
% weight the hog desciptor by the weights learned
pos_weighted_hog = training_row.*pos_weights';
weighted_rendered_hog = zeros(size_hog);
weighted_rendered_hog(ind_rowvec_to_hog) = pos_weighted_hog;
imhog = vl_hog('render', single(weighted_rendered_hog), 'numOrientations', num_orientation) ;
figure(1); 
subplot(2,2,1); imagesc(imhog); colormap('Winter'); title(sprintf('Positive-%s', filename));
freezeColors;
subplot(2,2,3); imagesc(eye_image);

% NEGATIVE WEIGHTS
neg_weights = weights;
neg_weights(neg_weights>0) = 0;
% weight the hog desciptor by the weights learned
neg_weighted_hog = training_row.*neg_weights';
weighted_rendered_hog = zeros(size_hog);
weighted_rendered_hog(ind_rowvec_to_hog) = neg_weighted_hog;
imhog = vl_hog('render', single(weighted_rendered_hog), 'numOrientations', num_orientation) ;
subplot(2,2,2); imagesc(imhog); colormap('Hot'); title(sprintf('Negative-%s', filename));
freezeColors;
subplot(2,2,4); imagesc(eye_image);

print('-djpeg', filename);