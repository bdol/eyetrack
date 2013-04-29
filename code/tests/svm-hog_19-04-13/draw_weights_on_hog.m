function draw_weights_on_hog(hog_op, weights, draw_neg, filename)

scale = 21;
x_size = size(hog_op,1);
y_size = size(hog_op,2);
hog_feat_dim = size(hog_op,3);
if(~draw_neg)
    weights(weights<0) = 0;
    separator_row_val = 1.2*max(weights(:));
else
    weights(weights>0) = 0;
    separator_row_val = 1.2*min(weights(:));
end

% imhog = vl_hog('render', hog_op, 'numOrientations',4) ;
glyph = zeros(scale*x_size, scale*y_size);
weights = reshape(weights, hog_feat_dim, length(weights)/hog_feat_dim);
separator_rows = separator_row_val*ones(scale - hog_feat_dim, size(weights,2));
weights = [weights; separator_rows];

c = reshape(weights,  scale*y_size, x_size )';

d = [];
for i =1:size(c,1)
    d = [d; repmat(c(i,:), hog_feat_dim,1);];
    d = [d; separator_row_val*ones(scale - hog_feat_dim, size(glyph,2))];
end
glyph = d;

% subplot(1,2,1); 
imagesc(glyph); set(gca, 'FontSize', 14);
title(sprintf('SVM Weights per HoG Bin. \nIn each bin, the HoG feature is a row. \nThis row is replicated %d times in each bin for clarity', hog_feat_dim));
% subplot(1,2,2); 
% imagesc(imhog); title('HoG Features rendered');

print('-djpeg', filename);