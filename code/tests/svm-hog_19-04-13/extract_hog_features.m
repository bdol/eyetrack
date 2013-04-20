function [hog_feat feat_vec_len] = extract_hog_features(images)

% HOG Parameters
cellSize = 10;
hog_feat = [];
for i = 1:length(images)
    temp = vl_hog(im2single(images(i).img), cellSize, 'numOrientations',4) ;
    hog_feat = [hog_feat; temp(:)'];
    feat_vec_len = size(hog_feat);
end

hog_feat = double(hog_feat);