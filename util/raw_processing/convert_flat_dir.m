% While convert_raw_dir converts images contained in the original raw data
% file format, this function takes a single dir of images and converts
% them.
clear;
raw_dir = '~/Desktop/calibration3';
out_dir = '~/Desktop/calibration3_png';
d = dir(raw_dir);
% dir_idx = [dir_list(:).isdir];
im_list = {d.name}';
im_list(ismember(im_list,{'.', '..'})) = [];

if ~exist(out_dir, 'dir')
    mkdir(out_dir);
end
for d = 1:numel(im_list)
    im_name = [raw_dir '/' im_list{d}];
    
    im_out_name = [out_dir '/' im_list{d}];
    fprintf('Processing images in %s ...\n', im_out_name);
    
    I = convert_image(im_name, 0);    
    
    imwrite(I, [im_out_name(1:end-3) 'png'], 'png');
end

fprintf('Done!\n');