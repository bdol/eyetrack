D = rdir('**/*.png');
addpath(genpath('../../third_party_libs'));
board_nums = 1:9;
feat_length = 10;
training_mat_left = zeros(length(D), feat_length);
training_lab_left = zeros(length(D),1);

for i = 1:length(D)
   im = imread(D(i).name);
   im = double(im);
   im = im./max(im(:));
   left = regexp(D(i).name, '.*left.*');
   if(~isempty(left))
    %    extract_features(im, feat_length);
    %    training_mat_left(i,:) = features;
       board_num = regexp(D(i).name,'.*_(\d)_\d_.*', 'tokens');
       temp = board_num{1};
       training_lab_left(i) = str2num(temp{1});
   end
end