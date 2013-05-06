function [hog_feat sample_hog ind num_orient] = extract_hog_features(images)

% HOG Parameters
cellSize = 8;
num_orient = 9;

hog_feat = [];
for i = 1:length(images)
    sample_hog = vl_hog(im2single(images(i).img), cellSize, 'numOrientations',num_orient) ;
    
    % Each cell's descriptor in a column...each cell's descriptors arranged
    % side by side
    % Each row will have descriptors arranged as:
    % (1,1) descriptor --> (1,2) ----> (1,3) ---> (1,4) 
    [X Y] = meshgrid(1:size(sample_hog,1),1:size(sample_hog,2));
    x = X(:);
    y = Y(:);
    x = repmat(x,1,size(sample_hog,3));
    y = repmat(y,1,size(sample_hog,3));
    x = reshape(x',size(x,1)*size(x,2),1);
    y = reshape(y',size(y,1)*size(y,2),1);
    z = repmat([1:size(sample_hog,3)]', size(sample_hog,1)*size(sample_hog,2),1);
    ind = sub2ind(size(sample_hog), x,y,z);
    hog_feat = [hog_feat; sample_hog(ind)'];
    
%     hog_feat = [hog_feat; temp(:)'];
    
end

hog_feat = double(hog_feat);